class Order
  # FIXME do that with the builtin i18n rails module
  STATES = [['en panier', 'cart'], ['payée', 'paid'], ['impayée', 'unpaid']]
  
  attr_accessor :names, :share_with, :tags

  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveRecord::Transitions
  
  referenced_in :user
  referenced_in :subscription
  
  references_many :packs, :dependent => :delete
  
  references_one :invoice
	
  embeds_one :product_order
  embeds_one :billing_address, :class_name => 'Address'
  embeds_one :shipping_address, :class_name => 'Address'
  
  field :state, :default => 'cart'
  field :tva_ratio, :type => Float, :default => 1.196
  field :description, :type => String
  field :number, :type => Integer
  field :manual, :type => Boolean, :default => false
  field :waybill_number, :type => String
  field :coliposte, :type => String
  field :document_destiny, :type => Integer, :default => 1
  field :payment_type, :type => Integer, :default => 0
  field :is_viewable_by_prescriber, :type => Boolean, :default => false
  field :is_current, :type => Boolean, :default => true

  index :number, :unique => true

  validates_uniqueness_of :number

  before_create :set_number
  before_create :set_waybill_number
  before_save :get_documents

  state_machine do
    state :cart
    state :paid
    state :scanned
    state :cancelled

    event :pay do
      transitions :to => :paid, :from => :cart
    end

    event :scanned do
      transitions :to => :scanned, :from => :paid, :on_transition => :do_send_scanned_notification
    end

    event :cancel do
      transitions :to => :cancelled, :from => [:cart, :paid, :scanned]
    end
  end

  def do_send_scanned_notification
    # OrderMailer.scanned_confirmation(self).deliver
  end

  scope :with_state, lambda{|ary| where(:state.in => [ary].flatten.map(&:to_s)) }
  scope :without_state, lambda{|ary| where(:state.nin => [ary].flatten.map(&:to_s)) }
  scope :current, :where => { :is_current => true }
  
  def total_in_cents_wo_vat
    _product = self.product_order
    
    price =  _product.price_in_cents_wo_vat.to_f rescue -1
    
    _product.product_option_orders.each do |option|
      price += option.price_in_cents_wo_vat.to_f rescue -1
    end

    return price
  end

  def total_in_cents_w_vat
    self.total_in_cents_wo_vat * self.tva_ratio
  end


  def total_in_euros_w_vat
    (self.total_in_cents_w_vat / 100).round_at(2)
  end

  def total_vat
    self.total_in_cents_w_vat - self.total_in_cents_wo_vat
  end

  def tax_rate
    (self.tva_ratio - 1) * 100.00
  end

  def waybill_color
    return "C"
  end

  def waybill_post_numerisation
    case self.document_destiny
      when 1 then "R"
      when 2 then "A"
      when 3 then "D"
    end
  end

  def generate_waybill_number
    bits = []
    bits << self.created_at.strftime("%y%m%d")
    bits << self.waybill_color
    bits << self.waybill_post_numerisation
    bits << ("%0.7d" % self.number)
    bits.join()
  end
  
  def original_document
    self.documents.originals.first rescue nil
  end
  
  def set_product_order product, options
    new_product_order = ProductOrder.new
    new_product_order.fields.keys.each do |k|
      setter =  (k+"=").to_sym
      value = product.send(k)
      new_product_order.send(setter, value)
    end

    self.product_order = new_product_order
    
    self.product_order.product_option_orders = []
    
    options.each do |option|
      product_option_order = ProductOptionOrder.new
      product_option_order.fields.keys.each do |k|
        setter =  (k+"=").to_sym
        value = option.send(k)
        product_option_order.send(setter, value)
      end
      product_option_order.position = option.product_group.position
      product_option_order.group = option.product_group.title
      self.product_order.product_option_orders << product_option_order
    end
    
    current_time = order.created_at rescue Time.now
    
    while current_time < Time.now
      monthly = self.user.find_or_create_reporting.find_or_create_monthly_by_date current_time
      subscription_detail = monthly.find_or_create_subscription_detail
      subscription_detail.set_product_order new_product_order
      subscription_detail.product_order.set_product_option_order options
      monthly.save
      
      current_time += 1.month
    end
  end
  
  def get_documents
    unless @names.blank?
      document_names = @names
      share_with_users = @share_with ||= []
      document_tags = @tags ||= ""
      
      Dir.chdir("#{Rails.root}/tmp/input_pdf_manual/")
      
      file_names = []
      Dir.foreach("./") { |file_name|
        file_names << file_name.sub(/.pdf/i,'') if file_name.match(/.pdf/i)
        File.rename(file_name, file_name.sub(/.PDF/,'.pdf')) if file_name.match(/.PDF/)
      }
      
      doc_names = []
      document_names.split(/\s*,\s*/).each do |doc_name|
        doc_names << doc_name
      end
      
      valid_names = []
      doc_names.each do |doc_name|
        file_names.each do |file_name|
          if doc_name.match(/[*]/)
            valid_names << file_name if file_name.match(/#{doc_name.sub('*','(.*)')}/i)
          else
            valid_names << file_name if file_name.match(/\A#{doc_name}\z/i)
          end
        end
      end

      valid_names.each do |file_name|
        number = self.packs.count + 1
        File.rename("#{file_name}.pdf","#{self.waybill_number}_#{number}.pdf")
      
        pack = Pack.new
        pack.order = self
        pack.name = file_name.gsub('_',' ')
        pack.users << self.user
        pack.save!
        pack.get_document "#{self.waybill_number}_#{number}"

        share_with_users.split(', ').each do |other|
          observer = User.find_by_email other
          unless observer.nil? && observer.id != self.user.id
            pack.users << observer
          end
        end
        pack.save!
    
        tags = [" "]
        document_tags.gsub('*','').downcase.split.each do |tag|
          tags << tag
        end

        pack.documents.each do |document|
          document_tag = DocumentTag.new
          document_tag.document = document.id
          document_tag.user = self.user.id
          g_tags = document_tag.generate
          document_tag.name += tags.join(' ')
          document_tag.save!
          share_with_users.split(', ').each do |other|
            observer = User.find_by_email other rescue nil
            unless observer.nil?
              document_tag = DocumentTag.new
              document_tag.document = document.id
              document_tag.user = observer.id
              document_tag.name = g_tags + tags.join(' ')
              document_tag.save!
            end
          end
        end
      end
    end
  end
  
protected

  def set_number
    self.number = DbaSequence.next(:order)
  end
  
  def set_waybill_number
    self.waybill_number = self.generate_waybill_number
  end

end
