# -*- encoding : UTF-8 -*-
class Scan::Period
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :user, inverse_of: :periods
  referenced_in :subscription, class_name: "Scan::Subscription", inverse_of: :periods
  references_many :documents, class_name: "Scan::Document", inverse_of: :period
  references_one :invoice, inverse_of: :period
  embeds_many :product_option_orders, as: :product_optionable
  embeds_one :delivery, class_name: "Scan::Delivery", inverse_of: :period
  
  field :start_at, type: Time,    default: Time.local(Time.now.year,Time.now.month,1,0,0,0)
  field :end_at,   type: Time,    default: Time.local(Time.now.year + 1,Time.now.month,1,0,0,0)
  field :duration, type: Integer, default: 1
  
  field :price_in_cents_wo_vat,       type: Integer, default: 0
  field :tva_ratio,                   type: Float,   default: 1.196

  # quantité limite
  field :max_sheets_authorized,            type: Integer, default: 100 # numérisés
  field :max_upload_pages_authorized,      type: Integer, default: 200 # téléversés
  field :quantity_of_a_lot_of_upload,      type: Integer, default: 200 # téléversés
  field :max_preseizure_pieces_authorized, type: Integer, default: 100 # presaisies
  field :max_expense_pieces_authorized,    type: Integer, default: 100 # notes de frais
  # prix excès
  field :unit_price_of_excess_sheet,      type: Integer, default: 12  # numérisés
  field :price_of_a_lot_of_upload,        type: Integer, default: 200 # téléversés
  field :unit_price_of_excess_preseizure, type: Integer, default: 0   # presaisies
  field :unit_price_of_excess_expense,    type: Integer, default: 0   # notes de frais
  
  field :documents_name_tags,      type: Array,   default: []
  field :pieces,                   type: Integer, default: 0
  field :sheets,                   type: Integer, default: 0
  field :pages,                    type: Integer, default: 0
  field :uploaded_pieces,          type: Integer, default: 0
  field :uploaded_sheets,          type: Integer, default: 0
  field :uploaded_pages,           type: Integer, default: 0
  field :paperclips,               type: Integer, default: 0
  field :oversized,                type: Integer, default: 0
  field :preseizure_pieces,        type: Integer, default: 0
  field :excess_preseizure_pieces, type: Integer, default: 0
  field :expense_pieces,           type: Integer, default: 0
  field :excess_expense_pieces,    type: Integer, default: 0
  
  scope :monthly,   where: { duration: 1 }
  scope :bimonthly, where: { duration: 2 }
  scope :quarterly, where: { duration: 3 }
  scope :annual,    where: { duration: 12 }
  
  # validate :attributes_year_and_month_is_uniq
  
  before_create :add_one_delivery!
  before_save :set_start_date, :set_end_date, :update_information

  def scanned_pages
    self.pages - self.uploaded_pages
  end
  
  def price_in_cents_w_vat
    self.price_in_cents_wo_vat * tva_ratio
  end
  
  def total_vat
    price_in_cents_w_vat - self.price_in_cents_wo_vat
  end
  
  def update_price
    self.price_in_cents_wo_vat = total_price_in_cents_wo_vat
  end
  
  def update_price!
    update_attributes(price_in_cents_wo_vat: total_price_in_cents_wo_vat)
  end
  
  def total_price_in_cents_wo_vat
    products_total_price_in_cents_wo_vat + price_in_cents_of_total_excess
  end
  
  def products_total_price_in_cents_wo_vat
    product_option_orders.sum(:price_in_cents_wo_vat) || 0
  end
  
  def price_in_cents_of_total_excess
    price_in_cents_of_excess_sheets +
    price_in_cents_of_excess_uploaded_pages +
    price_in_cents_of_excess_compta_pieces
  end
  
  def price_in_cents_of_excess_sheets
    excess = excess_sheets
    if excess > 0
      excess * unit_price_of_excess_sheet
    else
      0
    end
  end
  
  def price_in_cents_of_excess_uploaded_pages
    excess = excess_uploaded_pages
    if excess > 0
      (excess / quantity_of_a_lot_of_upload) * price_of_a_lot_of_upload +
      (excess % quantity_of_a_lot_of_upload > 0 ? price_of_a_lot_of_upload : 0)
    else
      0
    end
  end

  def price_in_cents_of_excess_compta_pieces
    price_in_cents_of_excess_preseizures + price_in_cents_of_excess_expenses
  end

  def price_in_cents_of_excess_preseizures
    excess = excess_preseizure_pieces
    if excess > 0
      excess * unit_price_of_excess_preseizure
    else
      0
    end
  end

  def price_in_cents_of_excess_expenses
    excess = excess_expense_pieces
    if excess > 0
      excess * unit_price_of_excess_expense
    else
      0
    end
  end
  
  def excess_sheets
    excess = sheets - uploaded_sheets - max_sheets_authorized
    excess > 0 ? excess : 0
  end
  
  def excess_uploaded_pages
    excess = uploaded_pages - max_upload_pages_authorized
    excess > 0 ? excess : 0
  end

  def excess_compta_pieces
    excess_preseizure_pieces + excess_expense_pieces
  end

  def get_excess_preseizure_pieces
    excess = get_preseizure_pieces - max_preseizure_pieces_authorized
    excess > 0 ? excess : 0
  end

  def get_excess_expense_pieces
    excess = get_expense_pieces - max_expense_pieces_authorized
    excess > 0 ? excess : 0
  end

  def compta_pieces
    preseizure_pieces + expense_pieces
  end

  def get_preseizure_pieces
    nb = 0
    documents.each do |document|
      nb += document.report.try(:preseizures).try(:count) || 0
    end
    nb
  end

  def get_expense_pieces
    nb = 0
    documents.each do |document|
      nb += document.report.try(:expenses).try(:count) || 0
    end
    nb
  end
  
  def set_product_option_orders(product_options)
    self.product_option_orders = []
    product_options.each do |product_option|
      new_product_option_order = ProductOptionOrder.new
      new_product_option_order.fields.keys.each do |k|
        setter =  (k+"=").to_sym
        value = product_option.send(k)
        new_product_option_order.send(setter, value)
      end
      self.product_option_orders << new_product_option_order
    end
  end
  
  def set_documents_name_tags
    tags = []
    self.documents.each do |document|
      if document.name.match(/\w+\s\w+\s\d{6}\sall$/)
        name = document.name.split
        tags << "b_#{name[1]} y_#{name[2][0..3]} m_#{name[2][4..5].to_i}"
      end
    end
    self.documents_name_tags = tags
  end
  
  def check_delivery
    if self.sheets - self.uploaded_sheets > 0
      self.delivery.state = "delivered"
    end
  end
  
  def update_information!
    update_information
    save
  end
  
  def update_information
    set_documents_name_tags
    self.pieces = self.documents.sum(:pieces) || 0
    self.sheets = self.documents.sum(:sheets) || 0
    self.pages = self.documents.sum(:pages) || 0
    self.uploaded_pieces = self.documents.sum(:uploaded_pieces) || 0
    self.uploaded_sheets = self.documents.sum(:uploaded_sheets) || 0
    self.uploaded_pages = self.documents.sum(:uploaded_pages) || 0
    self.paperclips = self.documents.sum(:paperclips) || 0
    self.oversized = self.documents.sum(:oversized) || 0
    self.preseizure_pieces = get_preseizure_pieces
    self.excess_preseizure_pieces = get_excess_preseizure_pieces
    self.expense_pieces = get_expense_pieces
    self.excess_expense_pieces = get_excess_expense_pieces
    check_delivery
    update_price
  end

  def render_json(viewer=self.user)
    hash = { documents: documents_json(viewer) }
    if viewer.is_admin or (viewer.is_prescriber && viewer == self.user.prescriber) or viewer.prescriber.try(:is_detail_authorized)
      hash.merge!({ options: options_json })
    end
    hash
  end
  
  def documents_json(viewer)
    total = {}
    total[:pieces] = 0
    total[:sheets] = 0
    total[:pages] = 0
    total[:uploaded_pieces] = 0
    total[:uploaded_sheets] = 0
    total[:uploaded_pages] = 0
    total[:paperclips] = 0
    total[:oversized] = 0
    
    lists = []
    documents.each do |document|
      list = {}
      list[:name] = document.name
      begin
        pack = document.pack
        if pack
          list[:historic] = pack.historic.each { |h| h[:date] = h[:date].strftime("%d/%m/%Y") }
          list[:link] = document.pack.documents.originals.first.content.url
        else
          list[:historic] = ""
          list[:link] = ""
        end
      rescue
        list[:link] = "#"
      end
      list[:pieces] = document.pieces.to_s
      list[:sheets] = document.sheets.to_s
      list[:pages] = document.pages.to_s
      list[:uploaded_pieces] = document.uploaded_pieces.to_s
      list[:uploaded_sheets] = document.uploaded_sheets.to_s
      list[:uploaded_pages] = document.uploaded_pages.to_s
      list[:paperclips] = document.paperclips.to_s
      list[:oversized] = document.oversized.to_s
      if document.report.try(:type)
        if document.report.try(:type) == "NDF"
          list[:report_id] = document.report.try(:id) || "#"
          list[:report_type] = document.report.try(:type) || ""
        elsif viewer.is_admin or viewer == self.user.prescriber && viewer != self.user
          list[:report_id] = document.report.try(:id) || "#"
          list[:report_type] = document.report.try(:type) || ""
        else
          list[:report_id] = "#"
        end
      else
        list[:report_id] = "#"
      end

      lists << list
      
      total[:pieces] += document.pieces
      total[:sheets] += document.sheets
      total[:pages] += document.pages
      total[:uploaded_pieces] += document.uploaded_pieces
      total[:uploaded_sheets] += document.uploaded_sheets
      total[:uploaded_pages] += document.uploaded_pages
      total[:paperclips] += document.paperclips
      total[:oversized] += document.oversized
    end
    
    total[:pieces] = total[:pieces].to_s
    total[:sheets] = total[:sheets].to_s
    total[:pages] = total[:pages].to_s
    total[:uploaded_pieces] = total[:uploaded_pieces].to_s
    total[:uploaded_sheets] = total[:uploaded_sheets].to_s
    total[:uploaded_pages] = total[:uploaded_pages].to_s
    total[:paperclips] = total[:paperclips].to_s
    total[:oversized] = total[:oversized].to_s
    
    {
      list: lists,
      total: total,
      excess: {
        compta_pieces: excess_compta_pieces.to_s,
        sheets: excess_sheets.to_s,
        uploaded_pages: excess_uploaded_pages.to_s
      },
      delivery: delivery.state
    }
  end
  
  def options_json
    lists = []
    product_option_orders.by_position.each do |option|
      list = {}
      if option.position != -1
        list[:group_title] = option.group_title
        list[:title] = option.title
        list[:price] = format_price option.price_in_cents_wo_vat
        lists << list
      end
    end
    invoice_link = ""
    invoice_number = ""
    unless self.user.prescriber.try(:is_centralizer)
      time = self.end_at + 1.day
      invoice = self.user.invoices.where(number: /^#{time.year}#{"%0.2d" % (time.month)}/).first
      if invoice.try(:content).try(:url)
        invoice_link = invoice.content.url
        invoice_number = invoice.number
      end
    end
    {
        list: lists,
        excess_sheets: format_price(price_in_cents_of_excess_sheets),
        excess_uploaded_pages: format_price(price_in_cents_of_excess_uploaded_pages),
        excess_compta_pieces: format_price(price_in_cents_of_excess_compta_pieces),
        total: format_price(price_in_cents_wo_vat),
        invoice_link: invoice_link,
        invoice_number: invoice_number
    }
  end
  
  def format_price(price_in_cents)
    ("%0.2f" % (price_in_cents/100.0)).gsub(".",",")
  end

  def current
    desc(:created_at).first
  end
  
private
  def attributes_year_and_month_is_uniq
    period = subscription.periods.where(:start_at.gte => start_at, :end_at.lte => end_at, duration: duration).first
    if period and period != self
      errors.add(:month, "Period, with start_at '#{start_at}' and end_at '#{end_at}', already exist for this customer.")
    else
      true
    end
  end
  
  def set_start_date
    year = start_at.year
    month = start_at.month
    if duration == 3
      if start_at.month <= 3
        month = 1
      elsif start_at.month <= 6
        month = 4
      elsif start_at.month <= 9
        month = 7
      elsif start_at.month <= 12
        month = 10
      end
    end
    self.start_at = Time.local year,month,1,0,0,0
  end
  
  def set_end_date
    self.end_at = start_at + duration.month - 1.second
  end

  def add_one_delivery!
    self.delivery = Scan::Delivery.new
  end
end
