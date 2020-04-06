class PaperProcess < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :user, optional: true
  belongs_to :period_document, optional: true
  belongs_to :order, optional: true

  self.inheritance_column = :_type_disabled
  after_save :update_order, if: proc { |e| e.type == 'kit' }

  validate  :customer_exist, if: proc { |e| e.customer_code_changed? }
  validates :journals_count, numericality: { greater_than: 0 }, if: proc { |e| e.journals_count.present? }
  validates :periods_count,  numericality: { greater_than: 0 }, if: proc { |e| e.periods_count.present? }
  validates_length_of :pack_name, within: 0..40, allow_nil: true
  validates_length_of :customer_code, within: 3..15
  validates_length_of :tracking_number, minimum: 13, maximum: 13, if: proc { |e| e.type != 'scan' }
  validates_inclusion_of :type, in: %w(kit receipt scan return)
  validates_inclusion_of :letter_type, in: [500, 1000, 3000], if: proc { |e| e.type == 'return' }
  validates_uniqueness_of :tracking_number, if: proc { |e| e.type != 'scan' }
  validates_uniqueness_of :order_id, if: proc { |e| e.type == 'kit' }
  validate  :order_belonging, if: proc { |e| e.type == 'kit' }

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

  def self.search(options)
    paper_processes = self.all

    if options[:customer_company].present?
      paper_processes = paper_processes.joins(:user).where('LOWER(users.company) LIKE ?', "%#{options[:customer_company].downcase}%")
    end

    paper_processes = paper_processes.where(type: options[:type]) if options[:type]
    paper_processes = paper_processes.where('pack_name LIKE ?',       "%#{options[:pack_name]}%")       if options[:pack_name]
    paper_processes = paper_processes.where('customer_code LIKE ?',   "%#{options[:customer_code]}%")   if options[:customer_code]
    paper_processes = paper_processes.where('tracking_number LIKE ?', "%#{options[:tracking_number]}%") if options[:tracking_number]

    if options[:created_at]
      options[:created_at].each do |operator, value|
        paper_processes = paper_processes.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    paper_processes
  end

  private

  def customer_exist
    unless User.customers.where(code: customer_code).first
      errors.add(:customer_code, :invalid)
    end
  end

  def order_belonging
    return errors.add(:order_id, 'non trouvé') unless Order.paper_sets.exists?(order_id)
    errors.add(:order_id, 'non trouvé pour ce client') unless order.user.code == customer_code if customer_code.present?
  end

  def update_order
    order.process if order.confirmed?
  end
end
