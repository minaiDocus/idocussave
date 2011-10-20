class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps

  field :number, :type => Integer
  
  referenced_in :order

  before_create :set_number

  def number
    txt = read_attribute(:number)
    self.order.created_at.strftime("%Y%m") + ("%0.6d" % txt)
  end

private

  def set_number
    self.number = DbaSequence.next(:invoice)
  end
end
