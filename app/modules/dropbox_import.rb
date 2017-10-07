class DropboxImport
  class << self
    def check
      DropboxBasic.all.each do |dropbox|
        begin
          dropbox.reload
        rescue ActiveRecord::RecordNotFound
          next
        end

        next unless dropbox.is_used? && dropbox.is_configured?
        next unless dropbox.user.is_prescriber || ([dropbox.user]+ dropbox.user.accounts).detect { |e| e.options.try(:upload_authorized?) }
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
        users += object.collaborators
        users.compact!
      else
        users = object
      end

      users.each do |user|
        dropbox = user.external_file_storage.try(:dropbox_basic)

        if dropbox && dropbox.is_used? && dropbox.is_configured?
          if dropbox.user.is_prescriber || ([dropbox.user]+ dropbox.user.accounts).detect { |e| e.options.try(:upload_authorized?) }
            dropbox.update_attribute(:changed_at, Time.now)
          end
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

    if user.is_prescriber
      default_path_prefix = "/exportation vers iDocus/#{user.code}"
    else
      default_path_prefix = '/exportation vers iDocus'
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
    if @dropbox.is_used? && @dropbox.is_configured? && customers.any?
      checked_at = Time.now
      has_more = true

      initialize_folders if @current_cursor.nil?

      while has_more && @current_cursor
        retryable = true
        begin
          result = client.list_folder_continue(@current_cursor)
        rescue DropboxApi::Errors::WriteError => e
          if e.message.match(/path\/not_found\//) && retryable
            initialize_folders
            retryable = false
            retry
          else
            raise
          end
        end

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
        User.where(id: ([user.id] + user.accounts.map(&:id))).order(code: :asc)
      end
      @customers = @customers.select { |c| c.options.try(:upload_authorized?) }
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

  def initialize_folders
    @dropbox.import_folder_paths = []
    @folders = nil
    update_folders
    begin
      @current_cursor = client.list_folder_get_latest_cursor(path: @current_path_prefix, recursive: true).cursor
    rescue DropboxApi::Errors::NotFoundError => e
      raise unless e.message.match(/path\/not_found/)
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
        if UploadedDocument.valid_extensions.include?(File.extname(file_path).downcase) && metadata.size <= 10.megabytes
          customer, journal_name, period_offset = get_info_from_path path

          begin
            Dir.mktmpdir do |dir|
              File.open File.join(dir, file_name), 'wb' do |file|
                client.download file_path do |content|
                  file.puts content.force_encoding('UTF-8')
                  file.flush
                end

                uploaded_document = UploadedDocument.new(file, file_name, customer, journal_name, period_offset, user, 'dropbox')
                if uploaded_document.valid?
                  logger.info "#{log_prefix}[SUCCESS]#{file_detail(uploaded_document)} #{file_path}"
                  client.delete file_path
                elsif uploaded_document.already_exist?
                  logger.info "#{log_prefix}[ALREADY_EXIST] #{file_path}"
                  mark_file_as_already_exist(path, file_name)
                else
                  logger.info "#{log_prefix}[INVALID] #{file_path}"
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

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_processing.log")
  end

  def log_prefix
    @log_prefix ||= "[Dropbox Import][#{user.code}]"
  end

  def file_detail(uploaded_document)
    file_size = ActionController::Base.helpers.number_to_human_size uploaded_document.temp_document.content_file_size
    "[TDID:#{uploaded_document.temp_document.id}][#{file_size}]"
  end
end
