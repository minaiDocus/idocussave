# -*- encoding : UTF-8 -*-
class ReturnLabels
  FILE_NAME = 'return_labels.pdf'
  FILE_PATH = File.join([Rails.root, 'files', 'kit', FILE_NAME])

  attr_accessor :scanned_by, :customers, :time

  def initialize(attributes = {})
    attributes.each do |key, value|
      send("#{key}=", value)
    end
  end

  def current_time
    time || Time.now
  end

  def users
    documents = Scan::Document.any_of({ :created_at.gt => current_time.beginning_of_day, :created_at.lt => current_time.end_of_day },
                                      { :scanned_at.gt => current_time.beginning_of_day, :scanned_at.lt => current_time.end_of_day }).
                               where(scanned_by: /#{@scanned_by}/)
    codes = documents.map { |e| e.name.split[0] }.uniq
    User.any_in(code: codes)
  end

  def users_ids
    @ids ||= users.distinct(:_id).map(&:to_s)
  end

  def render_pdf
    clients_data = []
    @customers.each do |(id, data)|
      if id.in?(users_ids)
        user = User.find id
        if data[:is_checked].present? && data[:is_checked] == 'true'
          number = data[:number].to_i
          number = 0 if number > 99
          client_data = {}
          client_data[:customer] = user
          client_data[:number] = number
          clients_data << client_data
          user.update_attribute(:return_label_generated_at, Time.now)
        end
      end
    end
    KitGenerator::labels FileSendingKitGenerator::to_return_labels(clients_data), FILE_NAME
  end

  def remove_pdf
    File.delete FILE_PATH if File.exist? FILE_PATH
  end

  def self.fetch_data(url, login, password, target_dir='/', service='')
    require "net/ftp"
    
    begin
      ftp = Net::FTP.new(url, login, password)
      
      ftp.chdir(target_dir)
      elements = ftp.nlst.sort
      folder = elements.select { |e| e.match /^#{Time.now.strftime('%Y%m%d')}$/ }.first
      
      if folder
        puts "[#{Time.now}] Looking at folder : #{folder}"
        ftp.chdir(folder)
        elements = ftp.nlst.sort
        pattern = "#{Pack::CODE_PATTERN} #{Pack::JOURNAL_PATTERN} #{Pack::PERIOD_PATTERN}"
        folders = elements.select { |f| f.match pattern }
        new_entries_count = 0
        folders.each do |folder|
          document_name = "#{folder} all"
          document = Scan::Document.find_by_name(document_name)
          unless document
            new_entries_count += 1
            puts "\t#{document_name}"
            Scan::Document.create(name: document_name, scanned_at: Time.now, scanned_by: service)
          end
        end
        puts "\tNothing new found." if new_entries_count == 0
      end
      
      ftp.close
    rescue Net::FTPConnectionError, Net::FTPError, Net::FTPPermError, Net::FTPProtoError, Net::FTPReplyError, Net::FTPTempError => e
      content = "#{e.class}<br /><br />#{e.message}"
      ErrorNotification::EMAILS.each do |email|
        NotificationMailer.notify(email, "[iDocus] Erreur lors de la mise à jour de l'état de livraison des documents", content).deliver
      end
      false
    end
  end
end
