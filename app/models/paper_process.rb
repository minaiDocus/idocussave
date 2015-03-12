# -*- encoding : UTF-8 -*-
class PaperProcess
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization
  belongs_to :user
  belongs_to :period_document

  field :type
  field :tracking_number
  field :customer_code
  field :journals_count, type: Integer
  field :periods_count,  type: Integer
  field :letter_type,    type: Integer
  field :pack_name

  validates_inclusion_of :type, in: %w(kit receipt scan return)
  validates_length_of :tracking_number, minimum: 13, maximum: 13, if: Proc.new { |e| e.type != 'scan' }
  validates_uniqueness_of :tracking_number, if: Proc.new { |e| e.type != 'scan' }
  validates_length_of :customer_code, within: 3..15
  validates_length_of :pack_name, within: 0..40, if: Proc.new { |e| e.pack_name.present? }
  validate :customer_exist, if: Proc.new { |e| e.customer_code_changed? }
  validates :journals_count, numericality: { greater_than: 0 }, if: Proc.new { |e| e.journals_count.present? }
  validates :periods_count,  numericality: { greater_than: 0 }, if: Proc.new { |e| e.periods_count.present? }
  validates_inclusion_of :letter_type, in: [500, 1000, 3000], if: Proc.new { |e| e.type == 'return' }

  scope :kits,     where: { type: 'kit' }
  scope :receipts, where: { type: 'receipt' }
  scope :scans,    where: { type: 'scan' }
  scope :returns,  where: { type: 'return' }

  scope :l500,  where: { letter_type: 500 }
  scope :l1000, where: { letter_type: 1000 }
  scope :l3000, where: { letter_type: 3000 }

  def self.to_csv
    criteria.map do |paper_process|
      [
        I18n.l(paper_process.created_at),
        paper_process.tracking_number,
        paper_process.customer_code,
        paper_process.journals_count,
        paper_process.periods_count,
        paper_process.letter_type
      ].join(';')
    end.join("\n")
  end

private

  def customer_exist
    unless User.customers.where(code: customer_code).first
      errors.add(:customer_code, :invalid)
    end
  end
end
