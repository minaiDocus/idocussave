class User
  include Mongoid::Document
  include Mongoid::Timestamps
  # Include default devise modules. Others available are:
  # :token_authenticatable, :trackable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable
         
  field :email
  field :is_admin, :type => Boolean, :default => false
  field :balance_in_cents, :type => Float, :default => 0.0
  field :use_debit_mandate, :type => Boolean, :default => false
  field :code, :type => String
  field :first_name, :type => String
  field :last_name, :type => String
  field :company, :type => String
  field :is_prescriber, :type => Boolean, :default => false
  field :inactive_at, :type => Time
  field :dropbox_delivery_folder, :type => String, :default => "iDocus_delivery/:code/:year:month/:account_book/"
  field :is_dropbox_extended_authorized, :type => Boolean, :default => false
  field :is_centraliser, :type => Boolean, :default => true
  field :is_detail_authorized, :type => Boolean, :default => false
  
  attr_accessor :client_ids, :is_inactive

  embeds_many :addresses
  
  # TODO remove those after migration
  references_many :clients, :class_name => "User", :inverse_of => :prescriber
  referenced_in :prescriber, :class_name => "User", :inverse_of => :clients
  references_and_referenced_in_many :reportings, :inverse_of => :viewer
  references_one :copy, :class_name => "Reporting::Customer", :inverse_of => :original_user
  
  references_many :periods, :class_name => "Scan::Period", :inverse_of => :user
  references_many :scan_subscriptions, :class_name => "Scan::Subscription", :inverse_of => :user
  references_many :scan_subscription_reports, :class_name => "Scan::Subscription", :inverse_of => :prescriber
  
  references_many :own_packs, :class_name => "Pack", :inverse_of => :owner
  references_and_referenced_in_many :packs
  
  references_many :my_account_book_types, :class_name => "AccountBookType", :inverse_of => :owner
  references_and_referenced_in_many :account_book_types,  :inverse_of => :clients
  
  references_many :reminder_emails
  references_many :invoices
  references_many :orders
  references_many :credits
  references_many :document_tags
  references_many :events
  references_many :subscriptions
  references_many :backups
  references_many :uploaded_files
  references_one :composition
  references_one :debit_mandate
  references_one :external_file_storage
  references_one :file_sending_kit
  references_one :pack_delivery_list
  
  scope :prescribers, :where => { :is_prescriber => true }
  scope :dropbox_extended_authorized, :where => { :is_dropbox_extended_authorized => true }
  scope :active, :where => { :inactive_at => nil }
  
  before_save :format_name, :update_clients, :set_inactive_at
  after_save :update_copy
  
  def active
    inactive_at == nil
  end
  
  def name
    f_name = self.first_name || ""
    l_name = self.last_name || ""
    result = [f_name,l_name].join(' ')
    unless result.blank?
      return result
    else
      return self.email
    end
  end
  
  def information
    f_info = []
    f_info << self.code if !self.code.blank?
    f_info << self.company if !self.company.blank?
    f_info << self.email
    f_info.join(" - ")
  end

  def self.find_by_email param
    User.where(:email => param).first
  end
  
  def self.find_by_emails params
    User.any_in(:email => params).entries
  end
  
  def is_subscribed_to_category number
    if self.subscriptions.where(:category => number).first
      true
    else
      false
    end
  end
  
  def update_copy
    find_or_create_copy.set_attributes
  end
  
  def find_or_create_copy
    copy = self.copy
    if copy
      copy
    else
      copy = Reporting::Customer.new
      copy.original_user = self
      copy.save
      copy
    end
  end
  
  def find_or_create_reporting
    copy = find_or_create_copy
    reporting = copy.reporting
    if reporting
      reporting
    else
      reporting = Reporting.new
      reporting.customer = copy
      self.reportings << reporting
      self.save
      reporting.save
      copy.save
      reporting
    end
  end
  
  def all_monthly
    Reporting::Monthly.any_in(:reporting_id => self["reporting_ids"])
  end
  
  def all_customers
    Reporting::Customer.any_in(:reporting_id => self["reporting_ids"])
  end
  
  def all_customers_sorted
    all_customers.sort do |a,b|
      if a.code != b.code
        a.code <=> b.code
      elsif a.company != b.company
        a.company <=> b.company
      elsif (a.first_name + " " + a.last_name) != (b.first_name + " " + b.last_name)
        (a.first_name + " " + a.last_name) <=> (b.first_name + " " + b.last_name)
      else
        a.email <=> b.email
      end
    end
  end
  
  def all_clients
    users = []
    all_customers.each do |customer|
      unless customer.original_user.nil?
        users << customer.original_user
      else
        users << customer
      end
    end
    users
  end
  
  def all_clients_sorted
    all_clients.sort do |a,b|
      if a.code != b.code
        a.code <=> b.code
      elsif a.company != b.company
        a.company <=> b.company
      elsif (a.first_name + " " + a.last_name) != (b.first_name + " " + b.last_name)
        (a.first_name + " " + a.last_name) <=> (b.first_name + " " + b.last_name)
      else
        a.email <=> b.email
      end
    end
  end
  
  def is_client? user
    unless self.is_prescriber
      (all_clients - [self]).include? user
    else
      false
    end
  end
  
  def is_active?
    if inactive_at.nil?
      true
    else
      false
    end
  end
  
  def is_inactive?
    if inactive_at.nil?
      false
    else
      true
    end
  end
  
  def scanning_subscription
    subscriptions.where(:category => 1).first
  end
  
  def find_or_create_scan_subscription
    if !scan_subscriptions.empty?
      scan_subscriptions.last
    else
      scan_subscription = Scan::Subscription.new
      scan_subscription.user = self
      scan_subscription.prescriber = self.prescriber || self
      scan_subscription.save
      scan_subscription
    end
  end
  
  def shipping_address
    self.addresses.for_shipping.first
  end
  
  def billing_address
    self.addresses.for_billing.first
  end
  
  def find_or_create_external_file_storage
    external_file_storage || ExternalFileStorage.create(:user_id => self.id)
  end

  def find_or_create_pack_delivery_list
    if pack_delivery_list
      pack_delivery_list
    else
      PackDeliveryList.create(:user_id => self.id)
    end
  end
  
protected
  def update_clients
    if self.is_prescriber && !self.client_ids.nil?
      new_client_ids = self.client_ids.split(/\s*,\s*/)
      
      # add
      new_clients = User.any_in(:_id => new_client_ids) - [self]
      new_clients.each do |new_client|
        new_client.prescriber = self
        new_client.save
        
        reporting = new_client.find_or_create_reporting
        self.reportings << reporting
        reporting.save
      end
      
      # remove
      old_clients = self.clients - new_clients - [self]
      old_clients.each do |old_client|
        old_client["prescriber_id"] = nil
        old_client.save
        
        reporting = old_client.find_or_create_reporting
        self["reporting_ids"] = self["reporting_ids"] - [reporting.id]
        reporting["viewer_ids"] = reporting["viewer_ids"] - [self.id]
        reporting.save
      end
    end
  end
  
  def set_inactive_at
    if self.is_inactive == "1"
      self.inactive_at = Time.now
    elsif self.is_inactive == "0"
      self.inactive_at = nil
    end
  end
  
  def format_name
    self.first_name = self.first_name.split.map(&:capitalize).join(" ") rescue ""
    self.last_name = self.last_name.upcase rescue ""
  end
end
