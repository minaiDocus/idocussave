# -*- encoding : UTF-8 -*-
class DropboxImportFolder
  class << self
    def check
      DropboxBasic.all.entries.each do |dropbox|
        if dropbox.is_used? && dropbox.is_configured? && (dropbox.user.is_prescriber || dropbox.user.options.try(:upload_authorized?))
          if dropbox.changed_at && (dropbox.checked_at.nil? || dropbox.changed_at > dropbox.checked_at)
            begin
              new(dropbox).check
            rescue DropboxAuthError => e
              if e.message.match(/User is not authenticated/)
                dropbox.update_attribute(:access_token, nil)
              else
                raise
              end
            end
            print '.'
          end
        end
      end
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
    if object.is_a? String
      @dropbox = DropboxBasic.find object
    else
      @dropbox = object
    end

    default_path_prefix = "/exportation vers iDocus/#{user.code}"
    unless user.is_prescriber
      default_path_prefix += " - #{user.company.gsub(/[\\\/\:\?\*\"\|&]/, '').strip}"
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
      @dropbox.update(
        delta_cursor:        @current_cursor,
        delta_path_prefix:   @current_path_prefix,
        import_folder_paths: folder_paths,
        checked_at:          checked_at
      )
    end
  end

private

  # Using a proxy to handle retryable error : timeout, code 500, code 503
  class Client
    def initialize(client)
      @client = client
    end

    def method_missing(name, *args)
      tried_count = 1
      begin
        @client.send(name, *args)
      rescue Errno::ETIMEDOUT, Timeout::Error, DropboxError => e
        if e.class.in?([Errno::ETIMEDOUT, Timeout::Error]) || e.message.match(/503 Service Unavailable|Internal Server Error/)
          if tried_count <= 3
            sleep(5*tried_count)
            tried_count += 1
            retry
          end
        end
        raise
      end
    end
  end

  def client
    @client ||= Client.new(@dropbox.client)
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
        customer_path = base_path.join "#{customer.code} - #{customer.company.gsub(/[\\\/\:\?\*\"\|&]/, '').strip}"
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
    if @folder_states
      @folder_states
    else
      new_folder_paths = folder_paths - @dropbox.import_folder_paths
      unused_folder_paths = @dropbox.import_folder_paths - folder_paths

      @folder_states = folder_paths.map do |folder_path|
        if new_folder_paths.include?(folder_path)
          [folder_path, false]
        else
          [folder_path, @initial_cursor.present?]
        end
      end

      @folder_states += unused_folder_paths.map do |folder_path|
        [folder_path, nil]
      end

      @folder_states
    end
  end

  def already_removed_folder(path)
    @folder_states.delete_if do |folder_state|
      folder_state[0].downcase == path
    end
  end

  def process_entry(path, metadata)
    if metadata.is_a?(Hash)
      if metadata['is_dir']
        folder_states.each do |folder_state|
          if folder_state.first.downcase == path
            folder_state[1] = true unless folder_state[1].nil?
          end
        end
      else
        process_file(path, metadata)
      end
    elsif File.extname(path).empty?
      folder_states.each do |folder_state|
        if folder_state.first.downcase.match /\A#{Regexp.quote(path)}/
          if folder_state[1] == true
            folder_state[1] = false
          elsif folder_state[1].nil?
            already_removed_folder(path)
          end
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
    unless file_name.match(/\(erreur fichier non valide pour iDocus\)/i)
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
      new_file_name = File.basename(file_name, '.*') + ' (erreur fichier non valide pour iDocus)' + File.extname(file_name)
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
    unused_folder_paths = folder_states.select { |path, state| state.nil? }.map(&:first)
    if user.is_prescriber
      paths = []
      unused_folder_paths.each do |unused_folder_path|
        is_already_added = false
        paths.each do |path|
          if unused_folder_path.match /\A#{path}/
            is_already_added = true
            break
          end
        end
        unless is_already_added
          customer, journal, period_offset = get_info_from_path unused_folder_path
          if customer && unused_folder_path.match(/\/#{customer.code} - #{customer.company.gsub(/[\\\/\:\?\*\"\|&]/, '').strip}\//)
            paths << unused_folder_path
          else
            paths << unused_folder_path.split('/')[0..3].join('/')
          end
        end
      end
      unused_folder_paths = paths
    end
    unused_folder_paths.each do |unused_folder_path|
      begin
        client.file_delete unused_folder_path
      rescue DropboxError => e
        raise unless e.message.match(/not found/)
      end
    end
  end

  def add_folders
    new_folder_paths = folder_states.select { |path, state| state == false }.map(&:first)
    new_folder_paths.uniq.each do |new_folder_path|
      begin
        client.file_create_folder new_folder_path
      rescue DropboxError => e
        raise unless e.message.match(/folder already exists/)
      end
    end
  end
end
