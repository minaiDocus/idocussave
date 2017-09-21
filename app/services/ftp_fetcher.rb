# -*- encoding : UTF-8 -*-
require 'net/ftp'

class FtpFetcher
  # FILENAME_PATTERN = /\A#{Pack::CODE_PATTERN}(_| )#{Pack::JOURNAL_PATTERN}(_| )#{Pack::PERIOD_PATTERN}(_| )#{Pack::POSITION_PATTERN}#{Pack::EXTENSION_PATTERN}\z/
  FILENAME_PATTERN = /\A#{Pack::CODE_PATTERN}(_| )#{Pack::JOURNAL_PATTERN}(_| )#{Pack::PERIOD_PATTERN}(_| )page\d{3,4}#{Pack::EXTENSION_PATTERN}\z/

  def self.fetch(url, username, password, dir = '/', provider = '')
    ftp = Net::FTP.new(url, username, password)
    ftp.passive = true

    ftp.chdir dir

    dirs = ftp.nlst.sort

    if (uncomplete_deliveries = check_uncomplete_delivery(ftp, dirs)).any?
      ScanService.notify_uncompleted_delivery uncomplete_deliveries
      ftp.chdir dir
      uncomplete_deliveries.each { |file_path| ftp.delete("#{file_path}.uncomplete") rescue false }
    end


    ready_dirs(dirs).each do |dir|
      ftp.chdir dir
      date      = dir[0..9]
      position = dir[11..-7] || 1

      corrupted_documents = []

      document_delivery = DocumentDelivery.find_or_create_by(date, provider, position)

      file_names = valid_file_names(ftp.nlst.sort)

      grouped_packs(file_names).each do |pack_name, file_names|
        documents = []
        file_names.each do |file_name|
          document = document_delivery.temp_documents.where(original_file_name: file_name).first

          if !document || (document && document.unreadable?)
            get_file ftp, file_name, clean_file_name(file_name) do |file|
              document = document_delivery.add_or_replace(file, original_file_name: file_name,
                                                                delivery_type: 'scan',
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

      ftp.chdir '..'

      if document_delivery.valid_documents?
        document_delivery.processed

        ftp.rename dir, fetched_dir(dir)
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

    ftp.close

  rescue Errno::ETIMEDOUT
    Rails.logger.info "[#{Time.now}] FTP: connect to #{url} : timeout"
    false

  rescue Net::FTPConnectionError, Net::FTPError, Net::FTPPermError, Net::FTPProtoError, Net::FTPReplyError, Net::FTPTempError, SocketError, Errno::ECONNREFUSED => e
    content = "#{e.class}<br /><br />#{e.message}"
    addresses = Array(Settings.first.notify_errors_to)

    unless addresses.empty?
      NotificationMailer.notify(addresses, "[iDocus] Erreur lors de la récupération des documents", content).deliver_later
    end

    false
  end


  def self.ready_dirs(dirs)
    dirs.select do |e|
      e.end_with?('ready')
    end
  end

  def self.check_uncomplete_delivery(ftp, dirs)
    dirs.select { |file_path| file_path.end_with?('uncomplete') && ftp.mtime(file_path).localtime < 30.minutes.ago }.inject([]) do |uncomplete_deliveries, file_path|
      expected_quantity  = ftp.gettextfile(file_path, nil).chop.to_i
      dir = File.basename(file_path, ".*")
      ftp.chdir dir
      if expected_quantity == ftp.nlst.size
        ftp.chdir '..'
        ftp.rename file_path, "#{dir}.uploaded"
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


  def self.get_file(ftp, file_name, new_file_name)
    Dir.mktmpdir do |dir|
      begin
        file = File.open(File.join(dir, new_file_name), 'w')
        ftp.getbinaryfile(file_name, file.path)

        yield(file)
      ensure
        file.close
      end
    end
  end
end
