class Pack::Report::Preseizure
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization,                          inverse_of: :preseizures
  belongs_to :user,                                  inverse_of: :preseizures
  belongs_to :report,    class_name: 'Pack::Report', inverse_of: :preseizures
  belongs_to :piece,     class_name: 'Pack::Piece',  inverse_of: :preseizures
  belongs_to :operation, class_name: 'Operation',    inverse_of: :preseizure
  has_many :accounts, class_name: 'Pack::Report::Preseizure::Account', inverse_of: :preseizure, dependent: :delete
  has_many :entries,  class_name: 'Pack::Report::Preseizure::Entry',   inverse_of: :preseizure, dependent: :destroy
  has_and_belongs_to_many :pre_assignment_deliveries

  field :name
  field :type
  field :date,            type: Time
  field :deadline_date,   type: Time
  field :operation_label
  field :observation,     type: String
  field :position,        type: Integer
  field :piece_number,    type: String
  field :amount,          type: Float
  field :currency,        type: String
  field :conversion_rate, type: Float
  field :third_party,     type: String
  field :fiduceo_id
  field :category_id,     type: Integer

  field :is_delivered,      type: Boolean, default: false
  field :delivery_tried_at, type: Time
  field :delivery_message
  field :is_locked,         type: Boolean, default: false

  scope :delivered,       where(is_delivered: true)
  scope :not_delivered,   where(is_delivered: false)
  scope :failed_delivery, where(:delivery_message.ne => '', :delivery_message.exists => true)

  scope :locked,     where(is_locked: true)
  scope :not_locked, where(is_locked: false)

  def piece_name
    name || piece.name rescue nil
  end

  def piece_content_url
    piece.try(:content).try(:url)
  end

  def self.by_position
    asc(:position)
  end

  # TODO remove me
  def period_date
    Time.local(year,month,1)
  end

  # TODO remove me
  def end_period_date
    if quarterly?
      period_date + 3.months
    else
      period_date.end_of_month
    end
  end

  # TODO refactor me
  def period_start_date
    period_date.to_date
  end

  # TODO refactor me
  def period_end_date
    end_period_date.to_date
  end

  # TODO refactor me
  def is_period_range_used
    report.user.options.pre_assignment_date_computed?
  end

  def piece_info
    piece_name.split(' ')
  end

  def syear
    piece_info[2][0..3]
  end

  def year
    syear.to_i
  end

  def smonth
    piece_info[2][4..5]
  end

  def month
    if annually?
      1
    elsif quarterly?
      (smonth[1].to_i * 3) - 2
    else
      smonth.to_i
    end
  end

  def annually?
    piece_info[2].size == 4
  end

  def quarterly?
    smonth[0] == 'T'
  end

  def amount_in_cents
    amount * 100 rescue nil
  end

  def self.by_position
    asc(:position)
  end
end
