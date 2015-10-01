# -*- encoding : UTF-8 -*-
class DropboxImportFolder
  class << self
    def check
      DropboxBasic.all.entries.each do |dropbox|
        if dropbox.is_used? && dropbox.is_configured?
          if dropbox.changed_at && (dropbox.checked_at.nil? || dropbox.changed_at > dropbox.checked_at)
            new(dropbox).check
            print '.'
          end
        end
      end
    end

    def changed(object)
      if object.is_a? User
        users = []
        users << user
        users << user.organization.leader
        users += user.groups.map(&:collaborators).flatten
      else
        users = object
      end
      users.each do |user|
        dropbox = user.external_file_storage.try(:dropbox_basic)
        if dropbox && dropbox.is_used? && dropbox.is_configured?
          dropbox.update_attribute(:changed_at, Time.now)
        end
      end
    end
  end

  def initialize(object)
    if object.is_a? String
      @dropbox = DropboxBasic.find object
    else
      @dropbox = object
    end

    default_path_prefix = "/exportation vers iDocus/#{user.code}"
    unless user.is_prescriber
      default_path_prefix += " - #{user.company.gsub(/[\\\/\:\?\*\"\|]/, '')}"
    end

    @current_cursor = @dropbox.delta_cursor
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
      while has_more
        delta = client.delta(@current_cursor, @current_path_prefix)
        delta['entries'].each do |entry|
          process_entry *entry
        end
        has_more = delta['has_more']
        @current_cursor = delta['cursor']
      end
      update_folders
      @dropbox.update_attributes(
        delta_cursor:        @current_cursor,
        delta_path_prefix:   @current_path_prefix,
        import_folder_paths: folder_paths,
        checked_at:          checked_at
      )
    end
  end

# private

  def client
    @client ||= @dropbox.client
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
      if user.is_prescriber && user.organization
        @customers = user.customers.active.asc(:code).entries
      else
        @customers = [user]
      end
    end
  end

  def folder_paths
    if @folder_paths
      @folder_paths
    else
      @folder_paths = []
      period_types = ['période actuelle', 'période précédente']
      base_path = Pathname.new '/exportation vers iDocus'
      base_path = base_path.join user.code if user.is_prescriber
      customers.each do |customer|
        customer_path = base_path.join "#{customer.code} - #{customer.company.gsub(/[\\\/\:\?\*\"\|]/, '')}"
        period_types.each do |period_type|
          period_path = customer_path.join period_type
          customer.account_book_types.asc(:name).each do |account_book_type|
            @folder_paths << period_path.join(account_book_type.name).to_s
          end
        end
      end
      @folder_paths
    end
  end

  def folder_states
    @folder_states ||= folder_paths.map { |path| [path, @initial_cursor.present?] }
  end

  def deleted_folder_paths
    folder_states.select { |path, is_present| !is_present }.map(&:first)
  end

  def process_entry(path, metadata)
    if metadata.is_a?(Hash)
      if metadata['is_dir']
        folder_states.each do |folder_state|
          if folder_state.first.downcase == path
            folder_state[1] = true
          end
        end
      else
        process_file(path, metadata)
      end
    elsif File.extname(path).empty?
      folder_states.each do |folder_state|
        if folder_state.first.downcase.match /\A#{Regexp.quote(path)}/
          folder_state[1] = false
        end
      end
    end
  end

  def valid_path?(path)
    folder_paths.select do |folder_path|
      folder_path.downcase == path
    end.present?
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

  def process_file(file_path, metadata)
    path = File.dirname file_path
    file_name = File.basename file_path
    unless file_name.match(/\(erreur fichier non valide pour iDocus\)/)
      if valid_path?(path)
        if UploadedDocument.valid_extensions.include?(File.extname(file_path)) && metadata['bytes'] <= 10.megabytes
          customer, journal_name, period_offset = get_info_from_path path
          begin
            file_contents = client.get_file file_path
            Dir.mktmpdir do |dir|
              File.open File.join(dir, file_name), 'wb' do |file|
                file.puts file_contents
                uploaded_document = UploadedDocument.new(file, file_name, customer, journal_name, period_offset, user)
                if uploaded_document.valid?
                  client.file_delete file_path
                else
                  mark_file_as_not_processable(path, file_name)
                end
              end
            end
          rescue DropboxError => e
            raise unless e.message == 'File has been deleted' || e.message.match(/not found/)
          end
        else
          mark_file_as_not_processable(path, file_name)
        end
      end
    end
  end

  def mark_file_as_not_processable(path, file_name)
    begin
      new_file_name = File.basename(file_name, '.*') + ' (erreur fichier non valide pour iDocus\)' + File.extname(file_name)
      client.file_move(File.join(path, file_name), File.join(path, new_file_name))
    rescue DropboxError => e
      raise unless e.message == 'File has been deleted' || e.message.match(/not found/)
    end
  end

  def update_folders
    remove_folders
    add_folders
  end

  def remove_folders
    unused_folder_paths = @dropbox.import_folder_paths - folder_paths
    unused_folder_paths.each do |unused_folder_path|
      begin
        client.file_delete unused_folder_path
      rescue DropboxError => e
        raise unless e.message.match(/not found/)
      end
    end
  end

  def add_folders
    new_folder_paths = folder_paths - @dropbox.import_folder_paths
    new_folder_paths += deleted_folder_paths
    new_folder_paths.uniq.each do |new_folder_path|
      begin
        client.file_create_folder new_folder_path
      rescue DropboxError => e
        raise unless e.message.match(/folder already exists/)
      end
    end
  end
end
