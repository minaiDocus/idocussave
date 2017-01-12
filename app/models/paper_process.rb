# -*- encoding : UTF-8 -*-
class PaperProcess < ActiveRecord::Base
  belongs_to :organization
  belongs_to :user
  belongs_to :period_document

  self.inheritance_column = :_type_disabled


  validate  :customer_exist, if: proc { |e| e.customer_code_changed? }
  validates :journals_count, numericality: { greater_than: 0 }, if: proc { |e| e.journals_count.present? }
  validates :periods_count,  numericality: { greater_than: 0 }, if: proc { |e| e.periods_count.present? }
  validates_length_of :pack_name, within: 0..40, allow_nil: true
  validates_length_of :customer_code, within: 3..15
  validates_length_of :tracking_number, minimum: 13, maximum: 13, if: proc { |e| e.type != 'scan' }
  validates_inclusion_of :type, in: %w(kit receipt scan return)
  validates_inclusion_of :letter_type, in: [500, 1000, 3000], if: proc { |e| e.type == 'return' }
  validates_uniqueness_of :tracking_number, if: proc { |e| e.type != 'scan' }



  scope :kits,     -> { where(type: 'kit') }
  scope :l500,     -> { where(letter_type: 500) }
  scope :l1000,    -> { where(letter_type: 1000) }
  scope :l3000,    -> { where(letter_type: 3000) }
  scope :scans,    -> { where(type: 'scan') }
  scope :returns,  -> { where(type: 'return') }
  scope :receipts, -> { where(type: 'receipt') }


  def self.to_csv(collection)
    collection.map do |paper_process|
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


  def self.search_for_collection_with_options_and_user(collection, options, user)
    if options[:customer_company].present?
      user_ids = user.customers.where('company LIKE ?', "%#{options[:customer_company]}%").distinct(:id).pluck(:id)
      collection = collection.where(user_id: user_ids)
    end

    collection = collection.where(type: options[:type]) if options[:type]
    collection = collection.where('pack_name LIKE ?',         "%#{options[:pack_name]}%")       if options[:pack_name]
    collection = collection.where('customer_code LIKE ?',   "%#{options[:customer_code]}%")  if options[:customer_code]
    collection = collection.where('tracking_number LIKE ?', "%#{options[:tracking_number]}%") if options[:tracking_number]

    if options[:updated_at]
      options[:updated_at].each do |operator, value|
        collection = collection.where("updated_at #{operator} '#{value}'")
      end
    end

    collection
  end


  private

  def customer_exist
    unless User.customers.where(code: customer_code).first
      errors.add(:customer_code, :invalid)
    end
  end
end
