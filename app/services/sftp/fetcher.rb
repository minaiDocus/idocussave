# -*- encoding : UTF-8 -*-
require 'net/sftp'

class Sftp::Fetcher
  # FILENAME_PATTERN = /\A#{Pack::CODE_PATTERN}(_| )#{Pack::JOURNAL_PATTERN}(_| )#{Pack::PERIOD_PATTERN}(_| )#{Pack::POSITION_PATTERN}#{Pack::EXTENSION_PATTERN}\z/
  FILENAME_PATTERN = /\A#{Pack::CODE_PATTERN}(_| )#{Pack::JOURNAL_PATTERN}(_| )#{Pack::PERIOD_PATTERN}(_| )page\d{3,4}#{Pack::EXTENSION_PATTERN}\z/

  def self.fetch(domain, username, password, dir = '/', provider = '')
    begin
      sftp = Net::SFTP.new
      sftp.connect url, 21
      sftp.login username, password
      sftp.passive = true

      Sftp::Fetcher::SFtpProcessor.new(sftp, dir).execute

      sftp.chdir dir

      dirs = sftp.nlst.sort

      if (uncomplete_deliveries = check_uncomplete_delivery(sftp, dirs)).any?
        Notifications::ScanService.new({deliveries: uncomplete_deliveries}).notify_uncompleted_delivery
        sftp.chdir dir
        uncomplete_deliveries.each { |file_path| sftp.delete("#{file_path}.uncomplete") rescue false }
      end


      ready_dirs(dirs).each do |dir|
        sftp.chdir dir
        date      = dir[0..9]
        position = dir[11..-7] || 1

        corrupted_documents = []

        document_delivery = DocumentDelivery.find_or_create_by(date, provider, position)

        file_names = valid_file_names(sftp.nlst.sort)

        grouped_packs(file_names).each do |pack_name, file_names|
          documents = []
          file_names.each do |file_name|
            document = document_delivery.temp_documents.where(original_file_name: file_name).first

            if !document || (document && document.unreadable?)
              get_file sftp, file_name, clean_file_name(file_name) do |file|
                pack_name = CustomUtils.replace_code_of(pack_name)

                document = document_delivery.add_or_replace(file, original_file_name: file_name,
                                                                  delivery_type: 'scan',
                                                                  api_name: 'scan',
                                                                  delivered_by: provider,
                                                                  pack_name: pack_name)
              end
            end

            documents << document
            corrupted_documents << document if document.unreadable? && !document.is_corruption_notified
          end

          if documents.select(&:unreadable?).count == 0 && documents.select(&:is_locked).count > 0
            document_ids = documents.map(&:id)
            TempDocument.where(id: document_ids).update_all(is_locked: false)
          end
        end

        sftp.chdir '..'

        if document_delivery.valid_documents?
          document_delivery.processed

          sftp.rename dir, fetched_dir(dir)

          document_delivery.temp_documents.group_by(&:user).each do |user, temp_documents|
            Notifications::Documents.new({user: user, new_count: temp_documents.count}).notify_new_scaned_documents
          end
        end

        # notify corrupted documents
        next unless corrupted_documents.count > 0

        subject = '[iDocus] Documents corrompus'
        content = "Livraison : #{dir}\n"
        content = "Total : #{corrupted_documents.count}\n"
        content << "Fichier(s) : #{corrupted_documents.map(&:original_file_name).join(', ')}"

        addresses = Array(Settings.first.notify_errors_to)

        unless addresses.empty?
          NotificationMailer.notify(addresses, subject, content)
        end

        corrupted_documents.each(&:corruption_notified)
      end

      sftp.close
    rescue Errno::ETIMEDOUT, EOFError => e
      System::Log.info('debug_sftp', "[#{Time.now}] SFTP: connect to #{url} : #{e.to_s}")
      false
    rescue Net::SFTPConnectionError, Net::SFTPError, Net::SFTPPermError, Net::SFTPProtoError, Net::SFTPReplyError, Net::SFTPTempError, SocketError, Errno::ECONNREFUSED => e
      content = "#{e.class}<br /><br />#{e.message}"
      addresses = Array(Settings.first.notify_errors_to)

      unless addresses.empty?
        NotificationMailer.notify(addresses, "[iDocus] Erreur lors de la récupération des documents ppp", content).deliver_later
      end

      false
    end
  end


  def self.ready_dirs(dirs)
    dirs.select do |e|
      e.end_with?('ready')
    end
  end

  def self.check_uncomplete_delivery(sftp, dirs)
    dirs.select { |file_path| file_path.end_with?('uncomplete') && sftp.mtime(file_path).localtime < 30.minutes.ago }.inject([]) do |uncomplete_deliveries, file_path|
      expected_quantity  = sftp.gettextfile(file_path, nil).chop.to_i
      dir = File.basename(file_path, ".*")
      sftp.chdir dir
      if expected_quantity == sftp.nlst.size
        sftp.chdir '..'
        sftp.rename file_path, "#{dir}.uploaded"
      else
        uncomplete_deliveries << dir
      end
      uncomplete_deliveries
    end
  end

  def self.grouped_packs(file_names)
    file_names.group_by do |e|
      result = e.scan(/\A(#{Pack::CODE_PATTERN}(_| )#{Pack::JOURNAL_PATTERN}(_| )#{Pack::PERIOD_PATTERN})/)[0][0]

      result.tr(' ', '_')
    end
  end


  def self.fetched_dir(dir)
    dir.sub('ready', 'fetched')
  end


  def self.clean_file_name(file_name)
    file_name.gsub(/\s/, '_').sub(/.PDF\z/, '.pdf').gsub(/page(\d+)(\.pdf)\z/i, '\1\2')
  end


  def self.valid_file_names(file_names)
    file_names.select do |e|
      e.match FILENAME_PATTERN
    end
  end


  def self.get_file(sftp, file_name, new_file_name)
    CustomUtils.mktmpdir('sftp_fetcher') do |dir|
      begin
        file = File.open(File.join(dir, new_file_name), 'w')
        sftp.getbinaryfile(file_name, file.path)

        yield(file)
      ensure
        file.close
      end
    end
  end

  class SftpProcessor
    def initialize(sftp, root)
      @root_path = "/nfs/ppp/"
      @sftp = sftp

      @sftp.chdir root

      @code_pattern = '[a-zA-Z0-9]+[%#]*[a-zA-Z0-9]*'
      @journal_pattern = '[a-zA-Z0-9]+'
      @period_pattern = '\d{4}([01T]\d)*'
    end

    def execute
      CustomUtils.add_chmod_access_into("/nfs/ppp/")

      dirs = @sftp.nlst.sort

      dirs.each do |f_path|
        file_path = @root_path + f_path

        if file_path && file_path.match(/\.uploaded$/)
          dir = File.basename file_path, '.*'
          dir = @root_path + dir

          if File.exist?(dir)
            if Dir.glob(dir + '/*').size == File.read(file_path).to_i
              File.rename dir, "#{dir}_processing"

              process("#{dir}_processing")

              File.delete file_path
              File.rename "#{dir}_processing", "#{dir}_ready"
            else
              File.rename file_path, "#{dir}.uncomplete"
            end
          end
        end
      end
    end

    def valid?(file_path)
      begin
        [1,2].include?(DocumentTools.pages_number(file_path))
      rescue GLib::Error
        false
      end
    end

    def process(path)
      file_paths = Dir.glob(path + '/*').sort

      grouped_packs(file_paths).each do |pack_name, file_names|
        invalid_files = []

        file_names.each do |file_path|
          unless valid?(file_path)
            invalid_files << file_path
          end
        end

        if invalid_files.any?
          dir = path.gsub('_processing', '_errors')
          FileUtils.makedirs(dir)
          FileUtils.chmod(0755, dir)

          move_to_error(dir, file_names, invalid_files)
        end
      end
    end

    def grouped_packs(file_names)
      file_names.group_by do |e|
        result = File.basename(e).scan(/\A(#{@code_pattern}(_| )#{@journal_pattern}(_| )#{@period_pattern})/)[0][0]
      end
    end

    def move_to_error(dir, file_names, invalid_files)
      file_names.each do |file_path|
        error_file_name = invalid_files.include?(file_path) ? File.basename(file_path, '.*') + '_error' + File.extname(file_path) : File.basename(file_path)
        FileUtils.mv file_path, "#{dir}/#{error_file_name}"
      end
    end
  end
end