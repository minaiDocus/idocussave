# -*- encoding : UTF-8 -*-
class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include Mongoid::Slug

  field :number,                type: String
  field :vat_ratio,             type: Float,   default: 1.2
  field :amount_in_cents_w_vat, type: Integer

  has_mongoid_attached_file :content,
    styles: {
      thumb: ["46x67>", :png]
    },
    path: ":rails_root/files/:rails_env/:class/:attachment/:id/:style/:filename",
    url: "/account/invoices/:id/download/:style"
  do_not_validate_attachment_file_type :content

  validates_presence_of :number
  validates_uniqueness_of :number

  index({ number: 1 }, { unique: true })

  slug :number

  before_validation :set_number

  belongs_to :organization
  # INFO : keeping those 3 relations for backward compatibility
  belongs_to :user
  belongs_to :subscription
  belongs_to :period

  class << self
    def find_by_number(number)
      find_by(number: number)
    end

    def archive(time=Time.now)
      file_path = archive_path archive_name(time - 1.month)
      invoices = Invoice.where(:created_at.gte => time.beginning_of_month, :created_at.lte => time.end_of_month)
      files_path = invoices.map { |e| e.content.path }
      DocumentTools.archive(file_path, files_path)
    end

    def archive_name(time=Time.now)
      "invoices_#{time.strftime('%Y%m')}.zip"
    end

    def archive_path(file_name)
      _file_name = File.basename file_name
      File.join Rails.root, 'files', Rails.env, 'archives', 'invoices', _file_name
    end
  end

  def create_pdf
    months = I18n.t('date.month_names').map { |e| e.capitalize if e }

    first_day_of_month = (self.created_at - 1.month).beginning_of_month.day
    current_month = months[self.created_at.month]
    previous_month = months[(self.created_at - 1.month).month]
    year = (self.created_at - 1.month).year
    month = (self.created_at - 1.month).month

    @total = 0
    @data = []

    time = self.created_at - 1.month

    customer_ids = organization.customers.map(&:_id)
    periods = Period.where(:user_id.in => customer_ids).where(:start_at.lte => time.dup, :end_at.gte => time.dup)

    basic_package_count     = 0
    mail_package_count      = 0
    scan_box_package_count  = 0
    retriever_package_count = 0
    annual_package_count    = 0

    periods.each do |period|
      period.product_option_orders.each do |option|
        case option.name
        when 'basic_package_subscription'
          basic_package_count += 1
        when 'mail_package_subscription'
          mail_package_count += 1
        when 'dematbox_package_subscription'
          scan_box_package_count += 1
        when 'retriever_package_subscription'
          retriever_package_count += 1
        when 'annual_package_subscription'
          annual_package_count += 1
        end
      end
    end

    ordered_paper_set_count = organization.orders.paper_sets.confirmed.where(:created_at.gte => time.beginning_of_month, :created_at.lte => time.end_of_month).count
    ordered_scanner_count   = organization.orders.dematboxes.confirmed.where(:created_at.gte => time.beginning_of_month, :created_at.lte => time.end_of_month).count

    @total = PeriodBillingService.amount_in_cents_wo_vat(time.month, periods)
    @data = [
      ["Nombre de dossiers actifs : #{periods.count}", ""],
      ["Forfaits et options iDocus pour " + previous_month.downcase + " " + year.to_s + " :", format_price(@total) + " €"]
    ]
    if basic_package_count > 0
      @data << ["- #{basic_package_count} forfait#{'s' if basic_package_count > 1} iDo'Basique", '']
    end
    if mail_package_count > 0
      @data << ["- #{mail_package_count} forfait#{'s' if mail_package_count > 1} iDo’Courrier", '']
    end
    if scan_box_package_count > 0
      @data << ["- #{scan_box_package_count} forfait#{'s' if scan_box_package_count > 1} iDo'Box", '']
    end
    if retriever_package_count > 0
      @data << ["- #{retriever_package_count} forfait#{'s' if retriever_package_count > 1} iDo'FacBanque", '']
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

    options = organization.subscription.periods.select { |period| period.start_at <= time and period.end_at >= time }.
      first.
      product_option_orders.
      by_position rescue []
    options.each do |option|
      @data << ["#{option.group_title} - #{option.title}", format_price(option.price_in_cents_wo_vat) + " €"]
      @total += option.price_in_cents_wo_vat
    end
    @address = organization.addresses.for_billing.first

    self.amount_in_cents_w_vat = (@total * self.vat_ratio).round

    Prawn::Document.generate "#{Rails.root}/tmp/#{self.number}.pdf" do |pdf|
      pdf.font "Helvetica"
      pdf.fill_color "49442A"

      # Header
      pdf.font_size 8
      pdf.default_leading 4
      header_data = [
        [
          "IDOCUS\n3, rue Copernic\n75116 Paris.",
          "SAS au capital de 50 000 €\nRCS PARIS: 804 067 726\nTVA FR12804067726",
          "contact@idocus.com\nwww.idocus.com\nTél : 0 811 030 177"
        ]
      ]

      pdf.table(header_data, width: 540) do
        style(row(0), borders: [:top,:bottom], border_color: "AFA6A6", text_color: "AFA6A6")
        style(columns(1), align: :center)
        style(columns(2), align: :right)
      end

      pdf.move_down 10
      pdf.image "#{Rails.root}/app/assets/images/logo/small_logo.png", width: 85, height: 40, at: [4, pdf.cursor]


      #  Body
      pdf.stroke_color "49442A"
      pdf.font_size 10
      pdf.default_leading 5

      # Address
      formatted_address = [@address.company, @address.first_name + " " + @address.last_name, @address.address_1, @address.address_2, @address.zip.to_s + " " + @address.city, @address.country].
        reject { |a| a.nil? or a.empty? }.
        join("\n")

      pdf.move_down 33
      pdf.bounding_box([252, pdf.cursor], width: 240) do
        pdf.text formatted_address, align: :right, style: :bold
      end

      # Information
      pdf.font_size(14) do
        pdf.move_down 30
        pdf.text "Facture n°" + self.number.to_s + " du " + (self.created_at - 1.month).end_of_month.day.to_s + " " + previous_month + " " + (self.created_at - 1.month).year.to_s, align: :left, style: :bold
      end

      pdf.move_down 14
      pdf.text "<b>Période concernée :</b> " + previous_month + " " + year.to_s, align: :left, inline_format: true

      unless organization
        pdf.move_down 7
        pdf.text "<b>Votre code client :</b> #{user.code}", align: :left, inline_format: true
      end

      # Detail
      pdf.move_down 30
      data = [["<b>Forfaits & Prestations</b>","<b>Prix HT</b>"]] + @data + [["",""]]

      pdf.table(data, width: 540, cell_style: { inline_format: true }) do
        style(row(0..-1), borders: [], text_color: "49442A")
        style(row(0), borders: [:bottom])
        style(row(-1), borders: [:bottom])
        style(columns(2), align: :right)
        style(columns(1), align: :right)
      end

      # Total
      pdf.move_down 7
      pdf.float do
        pdf.text_box "Total HT", at: [400, pdf.cursor], width: 60, align: :right, style: :bold
      end
      pdf.text_box format_price(@total) + " €", at: [470, pdf.cursor], width: 66, align: :right
      pdf.move_down 10
      pdf.stroke_horizontal_line 470, 540, at: pdf.cursor

      pdf.move_down 7
      pdf.float do
        pdf.text_box "TVA (20%)", at: [400, pdf.cursor], width: 60, align: :right, style: :bold
      end
      pdf.text_box format_price(@total * self.vat_ratio - @total) + " €", at: [470, pdf.cursor], width: 66, align: :right
      pdf.move_down 10
      pdf.stroke_horizontal_line 470, 540, at: pdf.cursor

      pdf.move_down 7
      pdf.float do
        pdf.text_box "Total TTC", at: [400, pdf.cursor], width: 60, align: :right, style: :bold
      end
      pdf.text_box format_price(@total * self.vat_ratio) + " €", at: [470, pdf.cursor], width: 66, align: :right
      pdf.move_down 10
      pdf.stroke_color "000000"
      pdf.stroke_horizontal_line 470, 540, at: pdf.cursor

      # Other information
      pdf.move_down 13
      pdf.text "Cette somme sera prélevée sur votre compte le 4 #{months[self.created_at.month].downcase} #{self.created_at.year}"

      pdf.move_down 7
      pdf.text "<b>Retrouvez le détails de vos consommations dans votre espace client dans le menu \"Mon Reporting\".</b>", align: :center, inline_format: true
    end

    self.content = File.new "#{Rails.root}/tmp/#{self.number}.pdf"
    self.save
    #File.delete "#{Rails.root}/tmp/#{self.number}.pdf"

  end

  def format_price price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros).gsub(".", ",")
  end

private

  def set_number
    unless self.number
      prefix = 1.month.ago.strftime('%Y%m')
      txt = DbaSequence.next('invoice_' + prefix)
      self.number = prefix + ("%0.4d" % txt)
    end
  end
end
