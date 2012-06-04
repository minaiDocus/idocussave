module AddressDeliveryList
  def self.process
    prescribers = []
    if PRESCRIBERS_CODE and PRESCRIBERS_CODE.empty?
      prescribers = User.prescribers.asc(:code).entries
    else
      prescribers = User.any_in(:code => PRESCRIBERS_CODE).asc(:code).entries
    end
    filepath = create_file_for_prescribers(prescribers)
    send_file(filepath)
  end

  def self.send_file(filepath, target_dir="depose2diadeis/iDocus_adresses_retour")
    if File.exist?(filepath)
      require "net/ftp"
      ftp = Net::FTP.new('193.168.63.12', 'depose', 'tran5fert')
      ftp.chdir(target_dir)
      ftp.put(filepath, File.basename(filepath))
      ftp.close
      true
    else
      puts "File #{filepath} doesn't exist, use create_file() first."
    end
  end
  
  def self.create_file_for_prescribers(prescribers)
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
  
  def self.create_file(users)
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
