# -*- encoding : UTF-8 -*-
class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to  :user
  belongs_to  :organization
  has_many    :invoices
  embeds_many :product_option_orders, as: :product_optionable

  field :number,                type: Integer
  field :period_duration,       type: Integer, default: 1
  field :price_in_cents_wo_vat, type: Integer, default: 0
  field :tva_ratio,             type: Float,   default: 1.2

  validates_uniqueness_of :number

  attr_accessor :requester, :permit_all_options

  before_create :set_number
  before_save :update_price

  def price_in_cents_w_vat
    price_in_cents_wo_vat * tva_ratio
  end

  def total_vat
    price_in_cents_w_vat - price_in_cents_wo_vat
  end

  def update_price
    self.price_in_cents_wo_vat = products_total_price_in_cents_wo_vat
  end

  def update_price!
    update_attributes(price_in_cents_wo_vat: products_total_price_in_cents_wo_vat)
  end

  def products_total_price_in_cents_wo_vat
    product_option_orders.sum(:price_in_cents_wo_vat) || 0
  end

  def products_total_price_in_cents_w_vat
    products_total_price_in_cents_wo_vat * tva_ratio
  end

  def fetch_options(_product)
    id = _product[:id]
    product = Product.find id
    _groups = _product[id] || []

    options = []
    option_ids = []
    _groups.each { |key, value| option_ids += value }

    _groups.each do |_group|
      group = ProductGroup.find(_group[0])
      required_option = nil
      if group.product_require
        required_option = group.product_require.product_options.any_in(_id: option_ids).first
      end
      _group[1].each do |option_id|
        option = ProductOption.find option_id
        use_old = false
        unless requester.try(:is_admin) || permit_all_options
          group_options = group.product_options
          selected_option = self.product_option_orders.select{ |so| group_options.select{ |go| so == go }.present? }.first
          use_old = selected_option ? option.position < selected_option.position : false
        end
        if use_old
          options << selected_option.dup
        else
          option_order = copy_product_option(option)
          option_order.price_in_cents_wo_vat = option_order.price_in_cents_wo_vat * required_option.quantity unless required_option.nil?
          options << option_order
        end
      end
    end
    options
  end

  # TODO extract into service object or form object
  def product=(_product)
    if requester.try(:is_admin)
      self.product_option_orders = fetch_options(_product)
    else
      extra_options = self.product_option_orders.select do |option|
        option.group_position >= 1000
      end.map(&:dup)
      self.product_option_orders = fetch_options(_product) + extra_options
    end
  end

  def copy_product_option(product_option)
    product_option_order = ProductOptionOrder.new
    product_option_order.fields.keys.each do |k|
      setter =  (k+"=").to_sym
      value = product_option.send(k)
      product_option_order.send(setter, value)
    end
    product_option_order
  end

  def self.current
    desc(:created_at).first
  end

private

  def set_number
    self.number ||= DbaSequence.next(:subscription)
  end
end
