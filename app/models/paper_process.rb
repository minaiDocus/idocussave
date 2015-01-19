# -*- encoding : UTF-8 -*-
class PaperProcess
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization
  belongs_to :user

  field :type
  field :tracking_number
  field :customer_code
  field :journals_count, type: Integer
  field :periods_count,  type: Integer

  validates_inclusion_of :type, in: %w(kit receipt return)
  validates_length_of :tracking_number, minimum: 13, maximum: 13
  validates_length_of :customer_code, within: 3..15
  validate :customer_exist, if: Proc.new { |e| e.customer_code_changed? }
  validates :journals_count, numericality: { greater_than: 0 }, if: Proc.new { |e| e.journals_count.present? }
  validates :periods_count,  numericality: { greater_than: 0 }, if: Proc.new { |e| e.periods_count.present? }

  scope :kits,     where: { type: 'kit' }
  scope :receipts, where: { type: 'receipt' }
  scope :returns,  where: { type: 'return' }

private

  def customer_exist
    unless User.customers.where(code: customer_code).first
      errors.add(:customer_code, :invalid)
    end
  end
end
