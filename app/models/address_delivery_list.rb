# -*- encoding : UTF-8 -*-
class AddressDeliveryList
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  has_mongoid_attached_file :content,
                            path: ":rails_root/files/#{Rails.env.test? ? 'test_' : ''}attachments/address_delivery_lists/:filename",
                            url: "/address_delivery_lists/:filename"

  field :is_checkpoint,    type: Boolean, default: false
  field :emails_notified,  type: Array,   default: []
  field :emails_to_notify, type: Array,   default: []
  field :error,            type: String

  default_scope where: { is_checkpoint: false }

  def to_s
    content = "#{self.created_at.strftime('%Y/%m/%d %H:%M:%S')}"
    if self.error.present?
      content << " - error"
    elsif self.is_checkpoint
      content << " - checkpoint"
    else
      content << " - success - notified to : #{self.emails_notified.join(', ')}"
    end
    content
  end

  class << self
    def process
      address_delivery_list = AddressDeliveryList.new
      if is_updated
        filepath = create_file_for_prescribers(prescribers)
        begin
          send_file(filepath)
          address_delivery_list.content = File.new filepath
          address_delivery_list.emails_to_notify = EMAILS_TO_NOTIFY
          EMAILS_TO_NOTIFY.each do |email|
            address_delivery_list.emails_notified << email if send_email(email)
          end
        rescue => e
          address_delivery_list.error = e.message
        end
      else
        puts "No update since last delivery."
        address_delivery_list.is_checkpoint = true
        puts "Checkpoint set at #{Time.now}."
      end
      address_delivery_list.save
    end

    def create_config_file
      begin
        File.open "#{Rails.root}/config/initializers/address_delivery_list.rb","w" do |f|
          f.write "AddressDeliveryList::ADDRESS = '193.168.63.12'\n"
          f.write "AddressDeliveryList::LOGIN = 'depose'\n"
          f.write "AddressDeliveryList::PASSWORD = 'tran5fert'\n"
          f.write "AddressDeliveryList::DELIVERY_DIR = 'depose2diadeis/iDocus_adresses_retour'\n"
          f.write "AddressDeliveryList::PRESCRIBERS_CODE  = []\n"
          f.write "AddressDeliveryList::EMAILS_TO_NOTIFY = []\n"
        end
      rescue
        puts "Cant't write file #{Rails.root}/config/initializers/address_delivery_list.rb"
      end
    end

    def checkpoint
      AddressDeliveryList.unscoped.desc(:created_at).first.try(:created_at) || Time.now
    end

    def prescribers
      (PRESCRIBERS_CODE.present? ? User.any_in(code: PRESCRIBERS_CODE) : User.prescribers).active.asc(:code).entries
    end

    def is_updated
      nb = 0
      time = checkpoint
      prescribers.each do |prescriber|
        prescriber.clients.active.each do |client|
          address = client.addresses.for_shipping.first
          if address and address.updated_at > time
            nb += 1
          end
        end
      end
      nb > 0 ? true : false
    end

    def send_email(email)
      AddressListUpdatedMailer.notify(email).deliver
    end

    def send_file(filepath, target_dir=DELIVERY_DIR)
      if File.exist?(filepath)
        require "net/ftp"
        ftp = Net::FTP.new(ADDRESS, LOGIN, PASSWORD)
        ftp.chdir(target_dir)
        ftp.put(filepath, File.basename(filepath))
        ftp.close
        true
      else
        puts "File #{filepath} doesn't exist, use create_file() first."
        false
      end
    end

    def create_file_for_prescribers(prescribers)
      users = []
      prescribers.each do |prescriber|
        prescriber.clients.active.asc(:code).each do |client|
          users << client if client != prescriber
        end
      end
      create_file(users)
    end

    def create_file(users)
      book = Spreadsheet::Workbook.new
      sheet1 = book.create_worksheet :name => "Address"
      sheet1.row(0).concat ["Code","Company","First name","Last name","Address 1","Address 2","Zip","City"]
      nb = 1

      users.each do |user|
        address = user.addresses.for_shipping.first
        if address
          data = [
              user.code,
              address.company,
              address.first_name,
              address.last_name,
              address.address_1,
              address.address_2,
              address.zip,
              address.city
          ]
          sheet1.row(nb).replace data
          nb += 1
        else
          puts "#{user.code} - error : address is nil"
        end
      end

      io = StringIO.new('')
      book.write(io)

      filepath = "#{Rails.root}/tmp/iDocus_adresses_retour_#{Time.now.strftime('%Y%m%d')}.xls"
      File.open(filepath,"w") do |f|
        f.write io.string
      end
      filepath
    end
  end
end