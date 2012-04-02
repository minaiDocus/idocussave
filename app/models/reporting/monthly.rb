class Reporting::Monthly
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :reporting, :inverse_of => :monthly
  embeds_one :delivery, :class_name => "Reporting::Delivery", :inverse_of => :monthly
  embeds_one :subscription_detail, :class_name => "Reporting::SubscriptionDetail", :inverse_of => :monthly
  
  embeds_many :documents, :class_name => "Reporting::Document", :inverse_of => :monthly
  
  after_create :create_delivery_state
  before_save :update_total_price_in_cents
  
  # Subscription default pack
  field :base_price_in_cents, :type => Integer, :default => 0
  field :max_sheets, :type => Integer, :default => 100
  field :max_custom_page, :type => Integer, :default => 100
  # Total
  field :total_price_in_cents, :type => Integer, :default => 0
  # Date
  field :year, :type => Integer, :default => Time.now.year
  field :month, :type => Integer, :default => Time.now.month
  
  validate :attributes_year_and_month_is_uniq
  
  scope :current_year, :where => { :year => Time.now.year }
  
public
  def self.current
    where(:year => Time.now.year, :month => Time.now.month).first
  end
  
  def self.previous
    where(:year => Time.now.year, :month => Time.now.month - 1).first
  end
  
  def self.of year
    where(:year => year)
  end
  
  def find_or_create_document_by_name name
    document = self.documents.where(:name => name).first
    if document
      document
    elsif
      self.documents.create(:name => name)
      #FIXME try another solution
      self.find_or_create_document_by_name name
    end
  end
  
  def find_or_create_subscription_detail
    if self.subscription_detail
      self.subscription_detail
    else
      self.subscription_detail = Reporting::SubscriptionDetail.new
      self.subscription_detail.save
      self.subscription_detail
    end
  end
  
protected
  def create_delivery_state
    self.delivery = Reporting::Delivery.new
    self.save
  end

  def attributes_year_and_month_is_uniq
    monthly = self.reporting.monthly.where(:year => self.year, :month => self.month).first
    if monthly && monthly != self
      errors.add(:month, "Monthly, with year(#{self.year}) month(#{self.month}) date, already exist for this customer.")
    else
      true
    end
  end
  
  def update_total_price_in_cents
    self.total_price_in_cents = self.base_price_in_cents
    price_of_excess_sheets
    price_of_excess_customs
    true
  end
  
  def price_of_excess_sheets
    total_sheets = 0
    self.documents.each do |document|
      total_sheets += document.sheets
    end
    
    total_sheets -= self.max_sheets
    
    if total_sheets > 0
      self.total_price_in_cents += total_sheets * 12
    end
  end
  
  def price_of_excess_customs
    total_customs = 0
    self.documents.each do |document|
      total_customs += document.uploaded_pages
    end
    
    total_customs -= self.max_custom_page
    
    while total_customs > 0
      self.total_price_in_cents += 200
      total_customs -= 100
    end
  end
  
end
