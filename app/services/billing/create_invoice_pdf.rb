class Billing::CreateInvoicePdf
  attr_accessor :data

  class << self
    def for_all
      #FIDC must not be treated here
      Organization.where.not(code: 'FIDC').billed.order(created_at: :asc).each do |organization|
        generate_invoice_of organization
      end

      #Generate FIDC invoice at last, which mean EG, FIDC, FBC have already been generated
      Organization.where(code: 'FIDC').billed.order(created_at: :asc).each do |organization|
        generate_invoice_of organization
      end

      archive_invoice
    end

    def for(organization_id, invoice_number=nil, _time=nil, _options={})
      organization = Organization.where(id: organization_id).billed.first
      return false unless organization

      generate_invoice_of organization, invoice_number, _time
    end

    #_options : [notify: send notification to admin,
    #            auto_upload: send invoice to ACC%IDO and invoice_settings]
    def generate_invoice_of(organization, invoice_number=nil, _time=nil, _options={})
      options = {}
      options[:notify]      = (_options[:notify] === false)? false : true
      options[:auto_upload] = (_options[:auto_upload] === false)? false : true

      begin
        time = _time.to_date.beginning_of_month + 15.days
      rescue
        time = 1.month.ago.beginning_of_month + 15.days
      end

      organization_period = organization.periods.where('start_date <= ? AND end_date >= ?', time.to_date, time.to_date).first

      return false if organization.addresses.select{ |a| a.is_for_billing }.empty?
      return false if organization_period.nil?
      return false if organization_period.invoices.present? && invoice_number.nil?

      invoice = if invoice_number.present?
                  Invoice.find_by_number(invoice_number) || Invoice.new(organization_id: organization.id, number: invoice_number)
                else
                  Invoice.new(organization_id: organization.id)
                end

      return false if invoice.try(:organization_id) != organization.id

      customers_periods = Period.where(user_id: organization.customers.active_at(time.to_date).map(&:id)).where('start_date <= ? AND end_date >= ?', time.to_date, time.to_date)

      # NOTE update all period before generating invoices
      customers_periods.each do |period|
        Billing::UpdatePeriodData.new(period).execute
        Billing::UpdatePeriod.new(period).execute
        print '.'
      end

      Billing::UpdateOrganizationPeriod.new(organization_period).fetch_all
      #Update discount only for organization and when generating invoice
      Billing::DiscountBilling.update_period(organization_period, time)

      return false if customers_periods.empty? && organization_period.price_in_cents_wo_vat == 0

      puts "Generating invoice for organization : #{organization.name}"
      invoice.period       = organization_period
      invoice.vat_ratio    = organization.subject_to_vat ? 1.2 : 1
      invoice.save
      print "-> Invoice #{invoice.number}..."
      Billing::CreateInvoicePdf.new(invoice, time, options[:auto_upload]).execute

      # organization.admins.each do |admin|
      #   Notifications::Notifier.new.create_notification({
      #     url: Rails.application.routes.url_helpers.account_profile_url({ panel: 'invoices' }.merge(ActionMailer::Base.default_url_options)),
      #     user: admin,
      #     notice_type: 'invoice',
      #     title: "Nouvelle facture disponible",
      #     message: "Votre facture pour le mois de #{I18n.l(invoice.period.start_date, format: '%B')} est maintenant disponible."
      #   }, false)
      # end

      # InvoiceMailer.delay(queue: :high).notify(invoice) if options[:notify]
    end

    def archive_invoice(time = Time.now)
      invoices   = Invoice.where("created_at >= ? AND created_at <= ?", time.beginning_of_month, time.end_of_month)
      return false unless invoices.present?

      invoices_files_path = invoices.map { |e| e.cloud_content_object.path }

      archive_name = "invoices_#{(time - 1.month).strftime('%Y%m')}.zip"

      CustomUtils.mktmpdir('create_invoice') do |dir|
        archive_path = DocumentTools.archive("#{dir}/#{archive_name}", invoices_files_path)

        _archive_invoice      = ArchiveInvoice.new
        _archive_invoice.name = archive_name

        _archive_invoice.cloud_content_object.attach(File.open(archive_path), archive_name) if _archive_invoice.save
      end
    end
  end

  def initialize(invoice, time=nil, auto_upload=true)
    @invoice = invoice
    @time    = time
    @auto_upload = auto_upload
  end

  def execute
    initialize_data_utilities

    make_invoice_pdf

    # @invoice.content = File.new "#{Rails.root}/tmp/#{@invoice.number}.pdf"
    @invoice.cloud_content_object.attach(File.open("#{Rails.root}/tmp/#{@invoice.number}.pdf"), "#{@invoice.number}.pdf") if @invoice.save

    #auto_upload_last_invoice if @auto_upload && @invoice.present? && @invoice.persisted? #WORKAROUND : deactivate auto upload invoices
  end

  def initialize_data_utilities
    time = @time || @invoice.created_at - 1.month
    @data    = []
    @total   = 0
    @months  = I18n.t('date.month_names').map { |e| e.capitalize if e }

    @previous_month = @months[time.month]
    @year  = time.year

    customer_ids = @invoice.organization.customers.active_at(time.to_date).map(&:id)

    periods = Period.where(user_id: customer_ids).where("start_date <= ? AND end_date >= ?", time.to_date, time.to_date)

    mail_package_count      = 0
    basic_package_count     = 0
    idox_package_count      = 0
    micro_package_count     = 0
    nano_package_count      = 0
    mini_package_count      = 0
    annual_package_count    = 0
    scan_box_package_count  = 0
    retriever_package_count = 0

    periods.each do |period|
      period.product_option_orders.each do |option|
        case option.name
        when 'basic_package_subscription'
          basic_package_count += 1
        when 'idox_package_subscription'
          idox_package_count += 1
        when 'mail_package_subscription'
          mail_package_count += 1
        when 'dematbox_package_subscription'
          scan_box_package_count += 1
        when 'retriever_package_subscription'
          retriever_package_count += 1
        when 'annual_package_subscription'
          annual_package_count += 1
        when 'micro_package_subscription'
          micro_package_count += 1
        when 'nano_package_subscription'
          nano_package_count += 1
        when 'mini_package_subscription'
          mini_package_count += 1
        end
      end
    end

    ordered_scanner_count   = @invoice.organization.orders.dematboxes.billed.where("created_at >= ? AND created_at <= ?", time.beginning_of_month, time.end_of_month).count
    ordered_paper_set_count = @invoice.organization.orders.paper_sets.billed.where("created_at >= ? AND created_at <= ?", time.beginning_of_month, time.end_of_month).count

    @total = Billing::PeriodBilling.amount_in_cents_wo_vat(time.month, periods)

    @data = [
      ["Nombre de dossiers actifs : #{periods.count}", ''],
      ['Forfaits et options iDocus pour ' + @previous_month.downcase + ' ' + @year.to_s + ' :', format_price(@total) + " €"]
    ]

    if micro_package_count > 0
      @data << ["- #{micro_package_count} forfait#{'s' if micro_package_count > 1} iDo'Micro", '']
    end

    if nano_package_count > 0
      @data << ["- #{nano_package_count} forfait#{'s' if nano_package_count > 1} iDo'Nano", '']
    end

    if mini_package_count > 0
      @data << ["- #{mini_package_count} forfait#{'s' if mini_package_count > 1} iDo'Mini", '']
    end

    if basic_package_count > 0
      @data << ["- #{basic_package_count} forfait#{'s' if basic_package_count > 1} iDo'Classique", '']
    end

    if idox_package_count > 0
      @data << ["- #{idox_package_count} forfait#{'s' if idox_package_count > 1} iDo'X", '']
    end

    if mail_package_count > 0
      @data << ["- #{mail_package_count} option#{'s' if mail_package_count > 1} Courrier", '']
    end

    if scan_box_package_count > 0
      @data << ["- #{scan_box_package_count} forfait#{'s' if scan_box_package_count > 1} iDo'Box", '']
    end

    if retriever_package_count > 0
      @data << ["- #{retriever_package_count} option#{'s' if retriever_package_count > 1} Automates", '']
    end

    if annual_package_count > 0
      @data << ["- #{annual_package_count} forfait#{'s' if annual_package_count > 1} Pack Annuel", '']
    end

    if ordered_paper_set_count > 0
      @data << ["- #{ordered_paper_set_count} commande#{'s' if ordered_paper_set_count > 1} de kit#{'s' if ordered_paper_set_count > 1}", '']
    end

    if ordered_scanner_count > 0
      @data << ["- #{ordered_scanner_count} commande#{'s' if ordered_scanner_count > 1} de scanner#{'s' if ordered_scanner_count > 1} iDo'Box", '']
    end

    options = begin
                @invoice.organization.subscription.periods.select { |period| period.start_date <= time && period.end_date >= time }
                            .first
                            .product_option_orders
                            .by_position
              rescue
                []
              end

    options.each do |option|
      @data << ["#{option.group_title} - #{option.title}", format_price(option.price_in_cents_wo_vat) + " €"] if @invoice.organization.code != 'FIDC'

      @total += option.price_in_cents_wo_vat
    end

    @address = @invoice.organization.addresses.for_billing.first

    @invoice.amount_in_cents_w_vat = (@total * @invoice.vat_ratio).round
  end

  def auto_upload_last_invoice
    begin
      user = User.find_by_code 'ACC%IDO' # Always send invoice to ACC%IDO customer

      file = File.new @invoice.cloud_content_object.path
      content_file_name = @invoice.cloud_content_object.filename

      uploaded_document = UploadedDocument.new( file, content_file_name, user, 'VT', 1, nil, 'invoice_auto', nil )

      logger_message_content(uploaded_document)

      auto_upload_invoice_setting(file, content_file_name)
    rescue => e
      System::Log.info('auto_upload_invoice', "[#{Time.now}] - [#{@invoice.id}] - [#{@invoice.organization.id}] - Error: #{e.to_s}")
    end
  end

  private

  def make_invoice_pdf
    @pdf.destroy if @pdf

    Prawn::Document.generate "#{Rails.root}/tmp/#{@invoice.number}.pdf" do |pdf|
      @pdf = pdf

      make_header

      make_body(@invoice.organization.name)

      make_footer

      @pdf
    end
  end

  def make_header
    @pdf.font 'Helvetica'
    @pdf.fill_color '49442A'

    @pdf.font_size 8
    @pdf.default_leading 4
    header_data = [
      [
        "IDOCUS\n17, rue Galilée\n75116 Paris.",
        "SAS au capital de 50 000 €\nRCS PARIS: 804 067 726\nTVA FR12804067726",
        "contact@idocus.com\nwww.idocus.com\nTél : 01 84 250 251"
      ]
    ]

    @pdf.table(header_data, width: 540) do
      style(row(0), borders: [:top, :bottom], border_color: 'AFA6A6', text_color: 'AFA6A6')
      style(columns(1), align: :center)
      style(columns(2), align: :right)
    end

    @pdf.move_down 10
    @pdf.image "#{Rails.root}/app/assets/images/logo/small_logo.png", width: 85, height: 40, at: [4, @pdf.cursor]

    @pdf.stroke_color '49442A'
    @pdf.font_size 10
    @pdf.default_leading 5

    formatted_address = [@address.company, @address.first_name + ' ' + @address.last_name, @address.address_1, @address.address_2, @address.zip.to_s + ' ' + @address.city, @address.country]
                        .reject { |a| a.nil? || a.empty? }
                        .join("\n")

    @pdf.move_down 33
    @pdf.bounding_box([252, @pdf.cursor], width: 240) do
      @pdf.text formatted_address, align: :right, style: :bold

      if @invoice.organization.vat_identifier
        @pdf.move_down 7

        @pdf.text "TVA : #{@invoice.organization.vat_identifier}", align: :right, style: :bold
      end
    end

    @pdf.font_size(14) do
      @pdf.move_down 30
      @pdf.text "Facture n°" + @invoice.number.to_s + ' du ' + (@invoice.created_at - 1.month).end_of_month.day.to_s + ' ' + @previous_month + ' ' + (@invoice.created_at - 1.month).year.to_s, align: :left, style: :bold
    end

    @pdf.move_down 14
    @pdf.text "<b>Période concernée :</b> " + @previous_month + ' ' + @year.to_s, align: :left, inline_format: true
  end

  def make_body(organization_name)
    @pdf.move_down 30
    data = [['<b>Forfaits & Prestations</b>', '<b>Prix HT</b>']]
    data +=  @data
    data += [['', '']]

    @pdf.table(data, width: 540, cell_style: { inline_format: true }) do
      style(row(0..-1), borders: [], text_color: '49442A')
      style(row(0), borders: [:bottom])
      style(row(-1), borders: [:bottom])
      style(columns(2), align: :right)
      style(columns(1), align: :right)
    end
  end

  def make_footer
    @pdf.move_down 7
    @pdf.float do
      @pdf.text_box 'Total HT', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
    end
    @pdf.text_box format_price(@total) + " €", at: [470, @pdf.cursor], width: 66, align: :right
    @pdf.move_down 10
    @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

    @pdf.move_down 7
    @pdf.float do
      if @invoice.organization.subject_to_vat
        @pdf.text_box 'TVA (20%)', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
      else
        @pdf.text_box 'TVA (0%)', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
      end
    end
    if @invoice.organization.subject_to_vat
      @pdf.text_box format_price(@total * @invoice.vat_ratio - @total) + " €", at: [470, @pdf.cursor], width: 66, align: :right
    else
      @pdf.text_box "0 €", at: [470, @pdf.cursor], width: 66, align: :right
    end
    @pdf.move_down 10
    @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

    @pdf.move_down 7
    @pdf.float do
      @pdf.text_box 'Total TTC', at: [400, @pdf.cursor], width: 60, align: :right, style: :bold
    end
    if @invoice.organization.subject_to_vat
      @pdf.text_box format_price(@total * @invoice.vat_ratio) + " €", at: [470, @pdf.cursor], width: 66, align: :right
    else
      @pdf.text_box format_price(@total) + " €", at: [470, @pdf.cursor], width: 66, align: :right
    end
    @pdf.move_down 10
    @pdf.stroke_color '000000'
    @pdf.stroke_horizontal_line 470, 540, at: @pdf.cursor

    # Other information
    @pdf.move_down 13
    @pdf.text "Cette somme sera prélevée sur votre compte le 4 #{@months[@invoice.created_at.month].downcase} #{@invoice.created_at.year}"

    if @invoice.organization.vat_identifier && !@invoice.organization.subject_to_vat
      @pdf.move_down 7
      @pdf.text 'Auto-liquidation par le preneur - Art 283-2 du CGI'
    end

    @pdf.move_down 7
    @pdf.text "<b>Retrouvez le détails de vos consommations dans votre espace client dans le menu \"Mon Reporting\".</b>", align: :center, inline_format: true
  end

  def auto_upload_invoice_setting(file, content_file_name)
    invoice_settings = @invoice.organization.invoice_settings || []

    invoice_settings.each do |invoice_setting|
      next unless invoice_setting.user.try(:options).try(:is_upload_authorized)

      uploaded_document = UploadedDocument.new( file, content_file_name, invoice_setting.user, invoice_setting.journal_code, 1, nil, 'invoice_setting', nil )
      logger_message_content(uploaded_document)
    end
  end

  def logger_message_content(uploaded_document)
    if uploaded_document.valid?
      System::Log.info('auto_upload_invoice', "[#{Time.now}] - [#{@invoice.id}] - [#{@invoice.organization.id}] - Uploaded")
    else
      System::Log.info('auto_upload_invoice', "[#{Time.now}] - [#{@invoice.id}] - [#{@invoice.organization.id}] - #{uploaded_document.full_error_messages}")
    end
  end

  def format_price price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros).gsub(".", ",")
  end
end
