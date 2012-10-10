# -*- encoding : UTF-8 -*-
require 'open-uri'

class TheBox
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :external_file_storage
  
  field :auth_token,    type: String,  default: ''
  field :ticket,        type: String,  default: ''
  field :path,          type: String,  default: ':code/:year:month/:account_book'
  field :is_configured, type: Boolean, default: false

  def get_ticket
    response = ""
    open("https://www.box.com/api/1.0/rest?action=get_ticket&api_key=#{Box::API_KEY}") do |f|
      f.each_line do |e|
        response << e
      end
    end
    self.ticket = response.scan(/<ticket>(.*)<\/ticket>/)[0][0] rescue ''
    save
    self.ticket
  end

  def get_authorize_url
    get_ticket unless self.ticket.present?
    "https://www.box.com/api/1.0/auth/#{self.ticket}"
  end

  def set_auth_token(token)
    update_attribute(:auth_token, token)
  end

  def get_auth_token
    response = ""
    open("https://www.box.com/api/1.0/rest?action=get_auth_token&api_key=#{Box::API_KEY}&ticket=#{self.ticket}") do |f|
      f.each_line do |e|
        response << e
      end
    end
    self.auth_token = response.scan(/<auth_token>(.*)<\/auth_token>/)[0][0] rescue ''
    if self.auth_token
      self.is_configured = true
    else
      self.is_configured = false
    end
    self.ticket = ''
    save
    self.auth_token
  end

  def new_session
    if self.auth_token.present?
      @account = Box::Account.new(Box::API_KEY)
      @account.authorize(self.auth_token)
      @account
    else
      nil
    end
  end
  
  def client
    @client ||= new_session
  end
  
  def is_configured?
    self.is_configured
  end

  def refresh_is_configured
    self.is_configured = client.authorized? rescue false
    save
    self.is_configured
  end
  
  def reset_session
    update_attributes(auth_token: '', ticket: '', is_configured: false)
  end
  
  def is_up_to_date(folder, filepath)
    filename = File.basename(filepath)
    begin
      results = folder.files.select { |e| e.name == filename }
    rescue => e
      Delivery::Error.create(sender: 'Box', state: 'searching', filepath: "#{File.join([path,filename])}", message: e.message, user_id: external_file_storage.user.id)
      results = []
    end 
    if results.any?
      size = results.first["size"]
      if size == File.size(filepath)
        true
      else
        false
      end
    else
      nil
    end
  end
  
  def is_not_up_to_date(path, filepath)
    !is_up_to_date(path, filepath)
  end
  
  def find_or_create_folder(path)
    parts = path.split('/').select{ |e| e.present? }
    folder = client.root
    parts.each do |part|
      tmp_folder = folder.folders.select{ |e| e.name == part }.first
      if tmp_folder
        folder = tmp_folder
      else
        folder = folder.create(part)
      end
    end
    folder
  end

  def deliver(filespath, delivery_path)
    clean_path = delivery_path.sub(/\/$/,"")
    folder = find_or_create_folder(clean_path)
    if folder
      filespath.each do |filepath|
        filename = File.basename(filepath)
        tries = 0
        begin
          if is_not_up_to_date(folder,filepath)
            print "sending #{clean_path}/#{filename} ..."
            folder.upload(filename)
            print "done\n"
          end
        rescue Timeout::Error
          tries += 1
          print "failed\n"
          puts "Trying again!"
          retry if tries <= 3
        rescue => e
          Delivery::Error.create(sender: 'Box', state: 'sending', filepath: "#{File.join([clean_path,filename])}", message: e.message, user_id: external_file_storage.user.id)
        end
      end
    end
  end
end
