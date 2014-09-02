# -*- encoding : UTF-8 -*-
require 'barby'
require 'barby/barcode/code_39'
require 'barby/outputter/png_outputter'
require 'prawn/measurement_extensions'

module FileSendingKitGenerator
  TEMPDIR_PATH = "#{Rails.root}/files/#{Rails.env}/kit/"

  def FileSendingKitGenerator.generate(clients_data,file_sending_kit, one_workshop_labels_page_per_customer=false)
    BarCode::init

    clients = to_clients(clients_data)

    KitGenerator::folder to_folders(clients_data), file_sending_kit
    KitGenerator::mail to_mails(clients), file_sending_kit
    KitGenerator::customer_labels to_labels(clients)
    KitGenerator::labels to_workshop_labels(clients_data, one_workshop_labels_page_per_customer)
  end

private

  def FileSendingKitGenerator.to_clients(clients_data)
    clients_data.map { |client_data| client_data[:user] }
  end

  def FileSendingKitGenerator.to_folders(clients_data)
    folders_data = []
    clients_data.each do |client_data|
      current_time = Time.now.beginning_of_month
      current_time += client_data[:start_month].month
      end_time = current_time + client_data[:offset_month].month
      while current_time < end_time
        client_data[:period_duration] = client_data[:user].scan_subscriptions.last.period_duration
        client_data[:user].account_book_types.asc(:name).each do |account_book_type|
          folders_data << to_folder(client_data, current_time, account_book_type)
        end
        current_time += client_data[:period_duration].month
      end
    end
    folders_data
  end

  def FileSendingKitGenerator.to_folder(client_data, period, account_book_type)
    part_number = 1
    user = client_data[:user]
    folder = {}
    folder[:code] = user.code
    folder[:company] = user.company.upcase
    if client_data[:period_duration] == 1
      folder[:period] = "#{KitGenerator::MOIS[period.month].upcase} #{period.year}"
    elsif client_data[:period_duration] == 3
      duration = period.month
      if duration < 4
        part_number = 1
      elsif duration < 7
        part_number = 2
      elsif duration < 10
        part_number = 3
      else
        part_number = 4
      end
      folder[:period] = "#{KitGenerator::TRIMESTRE[part_number]} #{period.year}"
    end
    folder[:account_book_type] = "#{account_book_type.name} #{account_book_type.description.upcase}"
    folder[:instructions] = account_book_type.instructions || ''
    if client_data[:period_duration] == 1
      folder[:file_code] = "#{user.code} #{account_book_type.name} #{period.year}#{"%0.2d" % period.month}"
    elsif client_data[:period_duration] == 3
      folder[:file_code] = "#{user.code} #{account_book_type.name} #{period.year}T#{part_number}"
    end
    folder[:barcode_path] = BarCode::generate_png(folder[:file_code])
    folder[:left_logo] = client_data[:left_logo]
    folder[:right_logo] = client_data[:right_logo]
    folder
  end

  def FileSendingKitGenerator.to_mails(users)
    users.map { |user| to_mail(user) }
  end

  def FileSendingKitGenerator.to_mail(user)
    mail = {}
    mail[:prescriber_company] = user.organization.leader.company
    mail[:client_email] = user.email
    mail[:client_password] = "v46hps32"
    mail[:client_code] = user.code
    mail[:client_address] = to_label(user)
    mail
  end

  def FileSendingKitGenerator.to_labels(users)
    users.map { |user| to_label(user) }
  end

  def FileSendingKitGenerator.to_label(user)
    address = user.addresses.for_shipping.first
    [
      user.company,
      user.name,
      address.address_1,
      address.address_2,
      "#{address.zip} #{address.city}"
    ].
    reject { |e| e.nil? or e.empty? }
  end

  def self.to_workshop_labels(clients_data, one_workshop_labels_page_per_customer=false)
    data = []
    clients_data.each do |client_data|
      user = client_data[:user]
      if user.scanning_provider && user.scanning_provider.addresses.any?
        data += to_workshop_label(client_data, one_workshop_labels_page_per_customer)
      end
    end
    data
  end

  def self.to_workshop_label(client_data, one_workshop_labels_page_per_customer=false)
    data = []
    user = client_data[:user]
    BarCode.generate_png(user.code, 20, 0)
    address = user.scanning_provider.addresses.first
    stringified_address = stringify_address(address)
    if one_workshop_labels_page_per_customer
      14.times do
        data << [user.code] + stringified_address
      end
    else
      current_time = Time.now.beginning_of_month
      current_time += client_data[:start_month].month
      end_time = current_time + client_data[:offset_month].month
      period_duration = user.scan_subscriptions.last.period_duration
      while current_time < end_time
        data << [user.code] + stringified_address
        current_time += period_duration.month
      end
    end
    data
  end

  def self.stringify_address(address)
    [
      address.company,
      address.address_1,
      address.address_2,
      [address.zip, address.city].join(' ')
    ].
    reject { |e| e.nil? or e.empty? }
  end

  def self.to_return_labels(clients_data)
    data = []
    clients_data.each { |client_data| data += to_return_label(client_data) }
    data
  end

  def self.to_return_label(client_data)
    customer = client_data[:customer]
    address = customer.addresses.for_shipping.first
    BarCode.generate_png(customer.code, 20, 0)
    stringified_address = stringify_return_address(address)
    data = []
    client_data[:number].times do
      data << [customer.code] + stringified_address
    end
    data
  end

  def self.stringify_return_address(address)
    [
      address.company,
      address.name,
      address.address_1,
      address.address_2,
      [address.zip, address.city].join(' ')
    ].
    reject { |e| e.nil? || e.empty? }
  end
end

module KitGenerator
  MOIS = [nil,"Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre"]
  TRIMESTRE = [nil,"1er Trimestre","2e Trimestre","3e Trimestre","4e Trimestre"]

  def KitGenerator.folder(folders,file_sending_kit)
    Prawn::Document.generate "#{FileSendingKitGenerator::TEMPDIR_PATH}/folders.pdf", :page_layout => :landscape, :page_size => "A3", :left_margin => 32, :right_margin => 7, :bottom_margin => 32, :top_margin => 7 do |pdf|
      folders.each_with_index do |folder,index|
        folder_bloc(pdf,folder,file_sending_kit)
        if !folders[index+1].nil?
          pdf.start_new_page(:page_size => "A3", :page_layout => :landscape, :left_margin => 32, :right_margin => 7, :bottom_margin => 32, :top_margin => 7)
        end
      end
    end
  end

  def KitGenerator.mail(mails,file_sending_kit)
    Prawn::Document.generate "#{FileSendingKitGenerator::TEMPDIR_PATH}/mails.pdf", :left_margin => 70, :right_margin => 70 do |pdf|
      pdf.font "Helvetica"

      mails.each_with_index do |mail,index|
        mail_bloc(pdf,mail,file_sending_kit)
        if !mails[index+1].nil?
          pdf.start_new_page(:left_margin => 70, :right_margin => 70)
        end
      end
    end
  end

  def KitGenerator.customer_labels(labels)
    Prawn::Document.generate "#{FileSendingKitGenerator::TEMPDIR_PATH}/customer_labels.pdf", :page_size => "A4", :margin => 0 do |pdf|
      pdf.font_size 11
      pdf.move_down 32
      nb = 0
      labels.each_with_index do |label,index|
        nb += 1
        if nb == 15
          pdf.start_new_page(:page_size => "A4", :margin => 0)
          pdf.move_down 32
          nb = 1
        end
        if index % 2 == 0
          pdf.float { customer_label_bloc(pdf,label) }
        else
          customer_label_bloc(pdf,label,297)
        end
      end
    end
  end

  def self.labels(labels, filename = 'workshop_labels.pdf')
    Prawn::Document.generate "#{FileSendingKitGenerator::TEMPDIR_PATH}/#{filename}", :page_size => "A4", :margin => 0 do |pdf|
      pdf.font_size 9
      pdf.move_down 32
      nb = 0
      labels.each_with_index do |label,index|
        nb += 1
        if nb == 15
          pdf.start_new_page(:page_size => "A4", :margin => 0)
          pdf.move_down 32
          nb = 1
        end
        if index % 2 == 0
          pdf.float { label_bloc(pdf,label) }
        else
          label_bloc(pdf,label,297)
        end
      end
    end
  end

private

  def KitGenerator.folder_bloc(pdf, folder, file_sending_kit)
    pdf.font_size 16

    # LEFT SIDE
    pdf.float do
      pdf.move_down 15
      pdf.bounding_box([0, pdf.cursor], :width => 531, :height => 785) do
        pdf.stroke_bounds
        pdf.bounding_box([15, pdf.cursor - 15], :width => 501, :height => 755) do
          pdf.text file_sending_kit.instruction, :inline_format => true
        end
      end
    end

    # RIGHT SIDE
    pdf.bounding_box([595, pdf.cursor], :width => 531, :height => 800) do
      pdf.move_down 9
      pdf.font_size 6
      pdf.text folder[:file_code], :align => :right

      pdf.move_down 6
      pdf.font_size 16
      # LOGO
      pdf.float do
        pdf.bounding_box([0, pdf.cursor], :width => 265, :height => 169) do
          pdf.image "#{Rails.root}/public#{file_sending_kit.left_logo_path}", :height => file_sending_kit.left_logo_height, :width => file_sending_kit.left_logo_width, :vposition => :center, :position => :center
        end
      end
      pdf.bounding_box([265, pdf.cursor], :width => 265, :height => 169) do
        pdf.image "#{Rails.root}/public#{file_sending_kit.right_logo_path}", :height => file_sending_kit.right_logo_height, :width => file_sending_kit.right_logo_width, :vposition => :center, :position => :center
      end

      pdf.move_down 10

      # BAR CODE
      pdf.bounding_box([0, pdf.cursor], :width => 531, :height => 84) do
        pdf.image folder[:barcode_path], :height => 56, :width => 282
      end

      pdf.move_down 10

      # INFORMATION
      pdf.float do
        pdf.bounding_box([0, pdf.cursor], :width => 416, :height => 512) do

          data = [["CODE :","<b>#{folder[:code]}</b>"],["NOM :","<b>#{folder[:company]}</b>"],["PERIODE :","<b>#{folder[:period]}</b>"],["JOURNAL :","<b>#{folder[:account_book_type]}</b>"]]
          data << ["INSTRUCTIONS :","<font size='11'>#{folder[:instructions]}"] if folder[:instructions].present?

          pdf.table(data, :width => 416, :cell_style => { :inline_format => true, :padding => [12, 4, 12, 4] }, :column_widths => { 0 => 150 }) do
            style(row(0..-1), :borders => [])
            style(columns(0), :align => :right)
          end
        end
      end

      pdf.float do
        pdf.image File.join([Rails.root,"app/assets/images/application/kit_info.png"]), :width => 105.mm, :height => 74.mm, :vposition => :bottom
      end

      # BAR CODE
      pdf.bounding_box([416, pdf.cursor], :width => 113, :height => 512) do
        pdf.move_down 409
        pdf.rotate(90, :origin => [30,100]) do
          pdf.image folder[:barcode_path], :height => 56, :width => 282, :position => -70, :vposition => 440
        end
      end
    end
  end

  def KitGenerator.mail_bloc(pdf, mail, file_sending_kit)
    pdf.font_size 8
    pdf.default_leading 4
    header_data = 	[
                              [
                              "IDOCUS / GREVALIS\n5, rue de Douai\n75009 Paris",
                              "Sarl au capital de 10.000 €\nRCS PARIS B520076852\nTVA FR21520076852",
                              "contact@idocus.com\nwww.idocus.com\nTél : 0 811 030 177"
                              ]
                            ]

    pdf.table(header_data, :width => 471, :column_widths => [157,157,157]) do
      style(row(0), :borders => [:top,:bottom], :border_color => "AFA6A6", :text_color => "AFA6A6")
      style(columns(0), :align => :left)
      style(columns(1), :align => :center)
      style(columns(2), :align => :right)
    end

    pdf.move_down 15
    pdf.image "#{Rails.root}/public#{file_sending_kit.logo_path}", :width => file_sending_kit.logo_width, :height => file_sending_kit.logo_height, :position => :center

    pdf.font_size 10

    pdf.move_down 12
    pdf.bounding_box([230, pdf.cursor], :width => 240) do
      pdf.text mail[:client_address].join("\n"), :align => :right
    end

    pdf.move_down 15

    pdf.text "Votre code client : <b>#{mail[:client_code]}</b>", :align => :left, :style => :italic, :inline_format => true

    pdf.move_down 8
    pdf.text "Paris, le #{Time.now.day} #{MOIS[Time.now.month]} #{Time.now.year}", :align => :right

    pdf.move_down 15

    pdf.text "Bonjour,"
    pdf.move_down 8
    pdf.text "Le cabinet #{mail[:prescriber_company]}, vous propose désormais un service de numérisation de toutes les pièces nécessaires à la tenue de votre comptabilité."
    pdf.move_down 8
    pdf.text "Cette prestation, assurée par iDocus, va vous permettre un accès rapide et très pratique à vos documents."
    pdf.text "Ils seront disponibles dans votre espace personnel sur le site <b>www.idocus.com</b>", :inline_format => true
    pdf.move_down 8
    pdf.text "Nous venons de vous créer un compte pour y accéder : "

    pdf.bounding_box([25, pdf.cursor], :width => 515) do
      pdf.text "-	 votre login : <b> #{mail[:client_email]}</b>", :inline_format => true
      pdf.text "-	 votre mot de passe : <b> #{mail[:client_password]} (à changer lors de votre première connexion)</b>", :inline_format => true
    end

    pdf.move_down 10
    pdf.text "Tous les mois, vous y retrouverez les fichiers issus de la numérisation de vos papiers."
    pdf.bounding_box([25, pdf.cursor], :width => 515) do
      pdf.text "-  Un fichier par chemise (AC, VT, BQ....)"
      pdf.text "-  Format des fichiers : PDF"
      pdf.text "-  Traitement d’OCR effectué (Reconnaissance Optique de Caractères)."
      pdf.text "-  L’interface du site vous permet aussi de télécharger, découper, regrouper les pages."
      pdf.text "-  Beaucoup de nouvelles fonctionnalités sont prévues dans les semaines et mois à venir, nous vous tiendrons informés."
    end

    pdf.move_down 10
    pdf.text "Vos documents qui sont déjà sous format électronique sont à intégrer dans le système iDocus grâce à la fonctionnalité « Téléverser » accessible dans votre espace personnel."

    pdf.move_down 10
    pdf.text "Le respect des consignes et des dates préconisées par #{mail[:prescriber_company]} ainsi que la  bonne utilisation des chemises et enveloppes ci-jointes garantiront l’efficacité de notre service."

    pdf.move_down 10
    pdf.text "Nous vous souhaitons une bonne utilisation."

    pdf.move_down 13
    pdf.text "L’équipe iDocus", :align => :center
  end

  def KitGenerator.customer_label_bloc(pdf, label, y=0)
    pdf.bounding_box([y, pdf.cursor], :width => 297, :height => 111) do
      pdf.move_down 18
      pdf.bounding_box([15, pdf.cursor], :width => 297) do
        label.each do |field|
          pdf.text field, :inline_format => true
          pdf.move_down 2
        end
      end
    end
  end

  def KitGenerator.label_bloc(pdf, label, y=0)
    pdf.bounding_box([y, pdf.cursor], :width => 297, :height => 111) do
      pdf.move_down 18
      pdf.bounding_box([15, pdf.cursor], :width => 297) do
        label.each_with_index do |field, index|
          if index == 0
            width, height = `identify -format \"%wx%h\" "#{BarCode::TEMPDIR_PATH}/#{field}.png"`.chop.split('x').map(&:to_i)
            w = width - ((width*20) / 100)
            pdf.float do
              pdf.bounding_box([0, pdf.cursor], :width => w) do
                pdf.image "#{BarCode::TEMPDIR_PATH}/#{field}.png", :height => height, :width => w
              end
            end
            pdf.bounding_box([w + 5, pdf.cursor], :width => 297-w, :height => height) do
              pdf.font_size 8
              pdf.move_down 8
              pdf.text field, :inline_format => true
            end
            pdf.move_down 4
          else
            pdf.font_size 9
            pdf.text field, :inline_format => true
            pdf.move_down 2
          end
        end
      end
    end
  end
end

module BarCode
  TEMPDIR_PATH = "#{Rails.root}/tmp/barcode"

  def BarCode.init
    unless File.exist?(TEMPDIR_PATH)
      Dir.mkdir(TEMPDIR_PATH)
    else
      system("rm #{TEMPDIR_PATH}/*.png")
    end
  end

  def BarCode.generate_png(text, height = 50, margin = 5)
    tempfile_path = "#{TEMPDIR_PATH}/#{text.gsub(" ","_")}.png"

    barcode = Barby::Code39.new(text)
    File.open(tempfile_path,"w") do |f|
      f.write barcode.to_png(:height => height, :margin => margin)
    end

    tempfile_path
  end
end
