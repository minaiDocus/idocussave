module AddressDeliveryList
  class << self
    def create_config_file
      begin
        File.open "#{Rails.root}/config/initializers/address_delivery_list.rb","w" do |f|
          f.write "AddressDeliveryList::ADDRESS = '193.168.63.12'\n"
          f.write "AddressDeliveryList::LOGIN = 'depose'\n"
          f.write "AddressDeliveryList::PASSWORD = 'tran5fert'\n"
          f.write "AddressDeliveryList::DELIVERY_DIR = 'depose2diadeis/iDocus_adresses_retour'\n"
          f.write "AddressDeliveryList::PRESCRIBERS_CODE  = []\n"
          f.write "AddressDeliveryList::EMAIL_TO_NOTIFY = ''\n"
        end
      rescue
        puts "Cant't write file #{Rails.root}/config/initializers/address_delivery_list.rb"
      end
    end
    
    def set_checkpoint
      data = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      begin
        File.open("#{Rails.root}/data/address_delivery_list_checkpoint.txt","w") do |f|
          f.write(data)
          puts "Checkpoint set to #{data}"
        end
      rescue
        puts "Can't write file #{Rails.root}/data/address_delivery_list_checkpoint.txt"
      end
    end
    
    def get_checkpoint
      time = Time.now
      if File.exist?("#{Rails.root}/data/address_delivery_list_checkpoint.txt")
        data = ""
        begin
          File.open("#{Rails.root}/data/address_delivery_list_checkpoint.txt","r") do |f|
            data = f.readlines.first
          end
        rescue
          puts "Can't open file #{Rails.root}/data/address_delivery_list_checkpoint.txt"
        end
        if data.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
          section = data.split(" ")
          date = section[0].split("-")
          hour = section[1].split(":")
          time = Time.local(date[0],date[1],date[2],hour[0],hour[1],hour[2])
        end
      end
      time
    end
    
    def prescribers
      prescribers = []
      if !PRESCRIBERS_CODE or (PRESCRIBERS_CODE and PRESCRIBERS_CODE.empty?)
        prescribers = User.prescribers.asc(:code).entries
      else
        prescribers = User.any_in(:code => PRESCRIBERS_CODE).asc(:code).entries
      end
    end
    
    def is_address_updated
      nb = 0
      time = get_checkpoint
      prescribers.each do |prescriber|
        prescriber.clients.each do |client|
          address = client.addresses.for_shipping.first
          if address and address.updated_at > time
            nb += 1
          end
        end
      end
      nb > 0 ? true : false
    end
    
    def process
      if is_address_updated
        filepath = create_file_for_prescribers(prescribers)
        if send_file(filepath)
          send_email
        end
      else
        puts "No update since last delivery."
      end
      set_checkpoint
    end
    
    def send_email
      AddressListUpdatedMailer.notify.deliver
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
        prescriber.clients.asc(:code).each do |client|
          if client != prescriber
            users << client
          end
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
      
      filepath = "#{Rails.root}/tmp/iDocus_adresses_retour_%0.4d%0.2d%0.2d.xls" % [Time.now.year, Time.now.month, Time.now.day]
      File.open(filepath,"w") do |f|
        f.write io.string
      end
      filepath
    end
    
  end
end
