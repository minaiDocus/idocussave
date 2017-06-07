class DropboxImport
  class << self
    def check
      DropboxBasic.all.each do |dropbox|
        next unless dropbox.is_used? && dropbox.is_configured? && (dropbox.user.is_prescriber || dropbox.user.options.try(:upload_authorized?))
        next unless dropbox.changed_at && (dropbox.checked_at.nil? || dropbox.changed_at > dropbox.checked_at)

        begin
          new(dropbox).check
        rescue DropboxApi::Errors::HttpError => e
          if e.message.match(/invalid_access_token/)
            dropbox.reset_access_token
            NotifyDropboxError.new(dropbox.user, 'dropbox_invalid_access_token').execute
          else
            raise
          end
        end

        print '.'
      end
      true
    end

    def changed(object)
      if object.is_a? User
        users = []
        users << object
        users << object.organization.leader
        users += object.groups.map(&:collaborators).flatten
        users.compact!
      else
        users = object
      end

      users.each do |user|
        dropbox = user.external_file_storage.try(:dropbox_basic)

        if dropbox && dropbox.is_used? && dropbox.is_configured? && (dropbox.user.is_prescriber || dropbox.user.options.try(:upload_authorized?))
          dropbox.update_attribute(:changed_at, Time.now)
        end
      end
    end
  end

  def initialize(object)
    @dropbox = if object.is_a? String
                 DropboxBasic.find object
               else
                 object
               end

    default_path_prefix = "/exportation vers iDocus/#{user.code}"

    unless user.is_prescriber
      default_path_prefix += " - #{user.company.gsub(/[\\\/\:\?\*\"\|&]/, '').strip}"
    end

    @current_cursor      = @dropbox.delta_cursor
    @current_path_prefix = @dropbox.delta_path_prefix

    if @current_path_prefix != default_path_prefix
      @current_cursor = nil
      @current_path_prefix = default_path_prefix
    end

    @initial_cursor = @current_cursor.try(:dup)
  end

  def check
    if @dropbox.is_used? && @dropbox.is_configured?
      checked_at = Time.now
      has_more = true

      if @current_cursor.nil?
        update_folders
        @current_cursor = client.list_folder_get_latest_cursor(path: @current_path_prefix, recursive: true).cursor
      end

      while has_more
        result = client.list_folder_continue(@current_cursor)
        result.entries.each do |entry|
          process_entry entry
        end

        has_more = result.has_more?
        @current_cursor = result.cursor
      end

      update_folders

      @dropbox.update(
        delta_cursor:        @current_cursor,
        delta_path_prefix:   @current_path_prefix,
        import_folder_paths: needed_folders,
        checked_at:          checked_at
      )
    end
  end

  def client
    @client ||= DropboxImport::Client.new(DropboxApi::Client.new(@dropbox.access_token))
  end

  def user
    if @user
      @user
    else
      @user = @dropbox.user
      @user.extend_organization_role
      @user
    end
  end

  def customers
    if @customers
      @customers
    else
      @customers = if user.is_prescriber && user.organization
        user.customers.active.order(code: :asc)
      else
        [user]
      end
    end
  end

  def needed_folders
    if @needed_folders
      @needed_folders
    else
      @needed_folders = []
      period_types = ['période actuelle', 'période précédente']
      base_path = Pathname.new '/exportation vers iDocus'
      base_path = base_path.join user.code if user.is_prescriber

      customers.each do |customer|
        customer_path = base_path.join "#{customer.code} - #{customer.company.gsub(/[\\\/\:\?\*\"\|&]/, '').strip}"
        account_book_type_names = customer.account_book_types.order(name: :asc).map(&:name)
        period_types.each do |period_type|
          period_path = customer_path.join period_type
          account_book_type_names.each do |account_book_type_name|
            @needed_folders << period_path.join(account_book_type_name).to_s
          end
        end
      end

      @needed_folders
    end
  end

  def folders
    if @folders
      @folders
    else
      new_paths    = needed_folders - @dropbox.import_folder_paths
      unused_paths = @dropbox.import_folder_paths - needed_folders

      @folders = needed_folders.map do |path|
        if new_paths.include?(path)
          DropboxImport::Folder.new(path, false)
        else
          DropboxImport::Folder.new(path, @initial_cursor.present?)
        end
      end
      @folders += unused_paths.map do |path|
        DropboxImport::Folder.new(path, nil)
      end

      @folders
    end
  end

  def process_entry(metadata)
    if metadata.is_a? DropboxApi::Metadata::File
      process_file metadata
    elsif metadata.is_a? DropboxApi::Metadata::Folder
      folders.each do |folder|
        if folder.path == metadata.path_display
          folder.created unless folder.to_be_destroyed?
        end
      end
    elsif metadata.is_a?(DropboxApi::Metadata::Deleted) && File.extname(metadata.name).empty?
      folders.each do |folder|
        next unless folder.path == metadata.path_display

        if folder.exist?
          folder.to_be_created
        elsif folder.to_be_destroyed?
          @folders -= [folder]
        end
      end
    end
  end

  def get_info_from_path(path)
    data = path.split('/')

    if user.is_prescriber
      customer_info, period_type, journal_name = data[3..5]
    else
      customer_info, period_type, journal_name = data[2..4]
    end

    code = customer_info.split(' - ')[0].upcase
    customer = customers.select { |c| code == c.code }.first
    period_offset = period_type == 'période actuelle' ? 0 : 1

    [customer, journal_name.upcase, period_offset]
  end

  def process_file(metadata)
    file_path = metadata.path_display
    path = File.dirname file_path
    file_name = File.basename file_path

    unless file_name =~ /\(erreur fichier non valide pour iDocus\)/i || file_name =~ /\(fichier déjà importé sur iDocus\)/i
      if needed_folders.include?(path)
        if UploadedDocument.valid_extensions.include?(File.extname(file_path)) && metadata.size <= 10.megabytes
          customer, journal_name, period_offset = get_info_from_path path

          begin
            Dir.mktmpdir do |dir|
              File.open File.join(dir, file_name), 'wb' do |file|
                client.download file_path do |content|
                  file.puts content.force_encoding('UTF-8')
                  file.flush
                end

                uploaded_document = UploadedDocument.new(file, file_name, customer, journal_name, period_offset, user)
                if uploaded_document.valid?
                  client.delete file_path
                elsif uploaded_document.already_exist?
                  mark_file_as_already_exist(path, file_name)
                else
                  mark_file_as_not_processable(path, file_name)
                end
              end
            end
          rescue DropboxApi::Errors::NotFoundError
          end
        else
          mark_file_as_not_processable(path, file_name)
        end
      end
    end
  end

  def mark_file_as_already_exist(path, file_name)
    mark_file_as_not_processable(path, file_name, ' (fichier déjà importé sur iDocus)')
  end

  def mark_file_as_not_processable(path, file_name, error_message=' (erreur fichier non valide pour iDocus)')
    new_file_name = File.basename(file_name, '.*') + error_message + File.extname(file_name)

    client.move(File.join(path, file_name), File.join(path, new_file_name), autorename: true)
  rescue DropboxApi::Errors::NotFoundError
  end

  def update_folders
    remove_folders
    add_folders
  end

  def remove_folders
    paths = []
    folders.each do |folder|
      if folder.to_be_destroyed?
        if user.is_prescriber
          customer, journal, period_offset = get_info_from_path folder.path
          if customer && folder.path.match(/\/#{customer.code} - #{customer.company.gsub(/[\\\/\:\?\*\"\|&]/, '').strip}\//)
            paths << [folder.path, false]
          else
            paths << [folder.path.split('/')[0..3].join('/'), true]
          end
        else
          paths << [folder.path, false]
        end
      end
    end
    paths.uniq.each do |path, is_parent_folder|
      begin
        client.delete path
      rescue DropboxApi::Errors::FolderConflictError, DropboxApi::Errors::NotFoundError
      end
      @folders.delete_if do |folder|
        if is_parent_folder
          folder.path =~ /\A#{path}/
        else
          folder.path == path
        end
      end
    end
  end

  def add_folders
    @folders.each do |folder|
      if folder.to_be_created?
        begin
          client.create_folder folder.path
        rescue DropboxApi::Errors::FolderConflictError
        end
        folder.created
      end
    end
  end
end
