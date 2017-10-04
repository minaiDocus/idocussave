class FTPImport
  class << self
    def execute
      Ftp.importable.each do |ftp|
        ImportFromFTPWorker.perform_async ftp.id
      end
      true
    end
  end

  class Client
    def initialize(message_prefix)
      @client = Net::FTP.new
      @message_prefix = message_prefix
    end

    def method_missing(name, *args, &block)
      grace_time = name == :getbinaryfile ? 120 : 5
      retries = 0
      begin
        log name, args

        Timeout::timeout grace_time do
          @client.send name, *args, &block
        end
      rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED, Timeout::Error, Net::FTPTempError, EOFError
        retries += 1
        if retries < 3
          min_sleep_seconds = Float(2 ** (retries/2.0))
          max_sleep_seconds = Float(2 ** retries)
          sleep_duration = rand(min_sleep_seconds..max_sleep_seconds).round(2)
          sleep sleep_duration
          retry
        end
        raise
      end
    end

    private

    def logger
      @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_debug_ftp_import.log")
    end

    def log(name, args)
      _args = name == :login ? ['[FILTERED]'] : args
      logger.info "[#{@message_prefix}] #{name} - #{_args.join(', ')}"
    end
  end

  def initialize(ftp)
    @ftp = ftp
    @ftp.previous_import_paths ||= []
  end

  def execute
    return false if not @ftp.configured?
    return false if not @ftp.organization
    return false if not_authorized?

    logger.info "#{log_prefix} START"
    start_time = Time.now

    return unless test_connection

    process

    sync_folder folder_tree

    client.close

    logger.info "#{log_prefix} END (#{(Time.now - start_time).round(3)}s)"

    @ftp.update import_checked_at: Time.now, previous_import_paths: import_folders.map(&:path)
  end

  private

  def client
    return @client if @client

    @client = Client.new(@ftp.organization.code)
    @client.connect @ftp.domain, @ftp.port
    @client.login @ftp.login, @ftp.password
    @client.passive = @ftp.is_passive

    @client
  end

  def test_connection
    client.nlst
    true
  rescue Errno::ETIMEDOUT, Errno::ECONNREFUSED
    # TODO : notify
    false
  end

  def customers
    @customers ||= @ftp.organization.customers.active.order(code: :asc)
  end

  def not_authorized?
    not customers.detect { |e| e.options.try(:upload_authorized?) }
  end

  # Pattern : /INPUT/code - journal (company)
  def folder_tree
    return @folder_tree if @folder_tree

    @folder_tree = FTPImport::Item.new root_path

    input_item = FTPImport::Item.new 'INPUT'
    @folder_tree.add input_item

    current_folder_paths = []
    customers.each do |customer|
      company = customer.company.gsub(/[\\\/\:\?\*\"\|&]/, '').strip
      journal_names = customer.account_book_types.order(name: :asc).map(&:name)

      journal_names.each do |journal_name|
        name = "#{customer.code} - #{journal_name} (#{company})"
        item = FTPImport::Item.new(name, true, false)
        item.customer = customer
        item.journal = journal_name
        input_item.add item
        item.created if @ftp.previous_import_paths.include?(item.path)
        current_folder_paths << item.path
      end
    end

    if same_import_root_path?
      unused_folder_paths = @ftp.previous_import_paths - current_folder_paths
      unused_folder_paths.each do |unused_folder_path|
        name = unused_folder_path.split('/')[2]
        input_item.add FTPImport::Item.new(name, true, nil)
      end
    end

    validate_item @folder_tree

    @folder_tree
  end

  # Clean up root path
  # ''
  # '/' => ''
  # 'abc' => '/abc'
  # '/abc' => '/abc'
  # '/abc/' => '/abc'
  # 'abc/123' => '/abc/123'
  # '/abc/123' => '/abc/123'
  # '/abc/123/' => '/abc/123'
  def root_path
    return @root_path if @root_path

    @root_path = @ftp.root_path
    unless @root_path == ''
      if @root_path == '/'
        @root_path = ''
      else
        @root_path = '/' + @root_path unless @root_path.match(/\A\//)
        @root_path = @root_path.sub(/\/\z/, '') if @root_path.match(/\/\z/)
      end
    end
    @root_path
  end

  def same_import_root_path?
    return false if @ftp.previous_import_paths.empty?
    previous_import_root_path = @ftp.previous_import_paths.first.split('/')[0..-3].join('/')
    current_import_root_path = @ftp.root_path.split('/').join('/')
    current_import_root_path == previous_import_root_path
  end

  def validate_item(item)
    if item.children.present?
      path_names = begin
        client.nlst item.path
      rescue Net::FTPTempError, Net::FTPPermError => e
        if e.message.match(/(No such file or directory)|(Directory not found)/)
          []
        else
          raise
        end
      end
      item.children.each do |child|
        result = path_names.detect do |path|
          child.path.match(/#{Regexp.quote(path.force_encoding('UTF-8'))}\z/)
        end
        if result
          child.created if child.to_be_created?
          validate_item child
        else
          if child.to_be_destroyed?
            child.orphan
          elsif child.exist?
            child.to_be_created
            validate_item child
          end
        end
      end
    end
  end

  def sync_folder(item)
    if item.to_be_created?
      client.mkdir item.path
      item.created
    elsif item.to_be_destroyed?
      remove_item item
    end

    item.children.each do |child|
      sync_folder child
    end
  end

  def remove_item(item)
    item.children.each do |child|
      remove_item child
    end
    # TODO : remove artefact folders too
    files = begin
      client.nlst item.path
    rescue Net::FTPTempError, Net::FTPPermError => e
      if e.message.match(/(No such file or directory)|(Directory not found)/)
        []
      else
        raise
      end
    end
    files.each do |file|
      client.delete file
    end
    client.rmdir item.path
    item.orphan
  end

  def import_folders
    @import_folders ||= last_items folder_tree
  end

  def last_items(item)
    if item.children.present?
      results = []
      item.children.each do |child|
        results += last_items(child)
      end
      results
    else
      [item]
    end
  end

  def process
    import_folders.each do |item|
      next if item.to_be_created?

      file_paths = begin
        client.nlst(item.path + '/*.*')
      rescue Net::FTPTempError, Net::FTPPermError => e
        if e.message.match(/No files found/)
          []
        else
          raise
        end
      end

      file_paths.each do |untrusted_file_path|
        file_name = File.basename(untrusted_file_path).force_encoding('UTF-8')
        file_path = File.join(item.path, file_name)

        next unless UploadedDocument.valid_extensions.include?(File.extname(file_name).downcase)
        next if file_name =~ /\(erreur fichier non valide pour iDocus\)/i || file_name =~ /\(fichier déjà importé sur iDocus\)/i
        next unless client.size(file_path) <= 10.megabytes

        Dir.mktmpdir do |dir|
          File.open File.join(dir, file_name), 'wb' do |file|
            client.getbinaryfile file_path, file

            uploaded_document = UploadedDocument.new file, file_name, item.customer, item.journal, 0, @ftp.organization, 'ftp'

            if uploaded_document.valid?
              logger.info "#{log_prefix}[SUCCESS]#{file_detail(uploaded_document)} #{file_path}"
              client.delete file_path
            elsif uploaded_document.already_exist?
              logger.info "#{log_prefix}[ALREADY_EXIST] #{file_path}"
              mark_file_as_already_exist item.path, file_name
            else
              logger.info "#{log_prefix}[INVALID] #{file_path}"
              mark_file_as_not_processable item.path, file_name
            end
          end
        end
      end
    end
  end

  def mark_file_as_already_exist(path, file_name)
    mark_file_as_not_processable path, file_name, ' (fichier déjà importé sur iDocus)'
  end

  def mark_file_as_not_processable(path, file_name, error_message=' (erreur fichier non valide pour iDocus)')
    new_file_name = File.basename(file_name, '.*') + error_message + File.extname(file_name)

    client.rename File.join(path, file_name), File.join(path, new_file_name)
  end

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_processing.log")
  end

  def log_prefix
    @log_prefix ||= "[FTP Import][#{@ftp.organization.code}]"
  end

  def file_detail(uploaded_document)
    file_size = ActionController::Base.helpers.number_to_human_size uploaded_document.temp_document.content_file_size
    "[TDID:#{uploaded_document.temp_document.id}][#{file_size}]"
  end
end
