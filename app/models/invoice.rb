# -*- encoding : UTF-8 -*-
class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include Mongoid::Slug
  
  field :number, type: String
  field :content_file_name
  field :content_file_type
  field :content_file_size, type: Integer
  field :content_updated_at, type: Time

  has_mongoid_attached_file :content,
    styles: {
      thumb: ["46x67>", :png]
    }

  validates_presence_of :number
  validates_uniqueness_of :number

  index :number, unique: true

  slug :number

  before_validation :set_number

  referenced_in :user
  referenced_in :subscription
  
  public

  def create_pdf
    mois = [nil,"Janvier","Février","Mars","Avril","Mai","Juin","Juillet","Août","Septembre","Octobre","Novembre","Décembre"]
    
    first_day_of_month = (self.created_at - 1.month).beginning_of_month.day
    current_month = mois[self.created_at.month]
    previous_month = mois[(self.created_at - 1.month).month]
    year = (self.created_at - 1.month).year
    month = (self.created_at - 1.month).month
    
    @total = 0
    @data = []
    
    prescriber = user.prescriber ? user.prescriber : user
    time = self.created_at - 1.month
    scan_subscription = user.scan_subscriptions.where(:start_at.lte => time, :end_at.gte => time).first
    if (prescriber != user and !prescriber.is_centralizer)
      # particular
      period = scan_subscription.find_or_create_period(time)
      options = period.product_option_orders
      options.each do |option|
        @data << [option.group_title + " : " + option.title, format_price(option.price_in_cents_wo_vat) + " €"]
      end
      @data << ["Dépassement",format_price(period.price_in_cents_of_total_excess) + " €"]
      @total += period.price_in_cents_wo_vat
    else
      # prescriber
      periods = Scan::Period.any_in(subscription_id: user.scan_subscription_reports.not_in(_id: [scan_subscription.id]).distinct(:_id)).
      where(:start_at.lte => time, :end_at.gte => time).
      select{ |period| period.end_at.month == time.month }

      @total += periods.sum(&:price_in_cents_wo_vat)

      @data = [
        ["Prestation iDocus pour le mois de " + previous_month.downcase + " " + year.to_s, format_price(@total) + " €"],
        ["Nombre de clients actifs : #{periods.count}",""]
      ]

      options = scan_subscription.periods.select { |period| period.start_at <= time and period.end_at >= time }.
      first.product_option_orders.
      where(:group_position.gte => 1000).
      by_position rescue []
      options.each do |option|
        @data << ["#{option.group_title} #{option.title}", format_price(option.price_in_cents_wo_vat) + " €"]
        @total += option.price_in_cents_wo_vat
      end
    end

    @address = self.user.addresses.for_billing.first

    Prawn::Document.generate "#{Rails.root}/tmp/#{self.number}.pdf" do |pdf|
      pdf.font "Helvetica"
      pdf.fill_color "49442A"

      # Header
      pdf.font_size 8
      pdf.default_leading 4
      header_data = [
        [
          "IDOCUS / GREVALIS\n5, rue de Douai\n75009 Paris",
          "Sarl au capital de 10.000 €\nRCS PARIS B520076852\nTVA FR21520076852",
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
        pdf.text "Facture n°" + self.number.to_s + " du 1 " + current_month + " " + year.to_s, align: :left, style: :bold
      end

      pdf.move_down 14
      pdf.text "<b>Période concernée :</b> " + previous_month + " " + year.to_s, align: :left, inline_format: true

      if (prescriber and prescriber != user and !prescriber.is_centralizer)
        pdf.move_down 7
        pdf.text "<b>Votre code client :</b> #{user.code}", align: :left, inline_format: true
      end

      # Detail
      pdf.move_down 30
      data = [["<b>Nature</b>","<b>Prix HT</b>"]] + @data + [["",""]]

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
        pdf.text_box "TVA (19.6%)", at: [400, pdf.cursor], width: 60, align: :right, style: :bold
      end
      pdf.text_box format_price(@total * 1.196 - @total) + " €", at: [470, pdf.cursor], width: 66, align: :right
      pdf.move_down 10
      pdf.stroke_horizontal_line 470, 540, at: pdf.cursor

      pdf.move_down 7
      pdf.float do
        pdf.text_box "Total TTC", at: [400, pdf.cursor], width: 60, align: :right, style: :bold
      end
      pdf.text_box format_price(@total * 1.196) + " €", at: [470, pdf.cursor], width: 66, align: :right
      pdf.move_down 10
      pdf.stroke_color "000000"
      pdf.stroke_horizontal_line 470, 540, at: pdf.cursor
      
      # Other information
      pdf.move_down 13
      pdf.text "Cette somme sera prélevée sur votre compte le 4 #{mois[self.created_at.month].downcase} #{self.created_at.year}"
      
      pdf.move_down 7
      pdf.text "Le détail de la prestation est consultable dans votre compte sur www.idocus.com"
      
      pdf.move_up 4
      pdf.text "Votre login d’accès au site : #{user.email}"
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
      txt = DbaSequence.next("invoice_"+Time.now.strftime("%Y%m"))
      self.slug = self.number = Time.now.strftime("%Y%m") + ("%0.4d" % txt)
    end
  end

end
