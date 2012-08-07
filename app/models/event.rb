# -*- encoding : UTF-8 -*-
class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :description, :type => String, :default => ""
  field :price_in_cents_wo_vat, :type => Integer, :default => 0
  field :type_number, :type => Integer, :default => 0
  
  # TODO remove me after migration
  field :amount_in_cents, :type => Integer, :default => 0
  
  validates_presence_of :title  
  
  referenced_in :user
  referenced_in :subscription
  references_one :invoice
  
  def price_in_cents_w_vat
    price_in_cents_wo_vat * 1.196
  end
end
