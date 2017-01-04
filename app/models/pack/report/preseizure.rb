class Pack::Report::Preseizure < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  belongs_to :user,                                  inverse_of: :preseizures
  belongs_to :piece,     class_name: 'Pack::Piece',  inverse_of: :preseizures
  belongs_to :report,    class_name: 'Pack::Report', inverse_of: :preseizures
  belongs_to :operation, class_name: 'Operation',    inverse_of: :preseizure
  belongs_to :organization,                          inverse_of: :preseizures

  has_many :entries,  class_name: 'Pack::Report::Preseizure::Entry',   inverse_of: :preseizure, dependent: :destroy
  has_many :accounts, class_name: 'Pack::Report::Preseizure::Account', inverse_of: :preseizure, dependent: :destroy

  has_and_belongs_to_many :remote_files, foreign_key: 'pack_report_preseizure_id'
  has_and_belongs_to_many :pre_assignment_deliveries


  scope :locked,          -> { where(is_locked: true) }
  scope :delivered,       -> { where(is_delivered: true) }
  scope :not_locked,      -> { where(is_locked: false) }
  scope :by_position,     -> { order(position: :asc) }
  scope :not_delivered,   -> { where(is_delivered: false) }
  scope :failed_delivery, -> { where.not(delivery_message: '') }


  def piece_name
    piece.try(:name) || report.name
  end


  def piece_content_url
    piece.try(:content).try(:url)
  end


  def period_date
    Time.local(year, month, 1)
  end


  def end_period_date
    if quarterly?
      period_date + 3.months
    elsif annually?
      period_date + 12.months
    else
      period_date.end_of_month
    end
  end


  def period_start_date
    period_date.to_date
  end


  def period_end_date
    end_period_date.to_date
  end


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
    (amount * 100).round
  rescue
    nil
  end
end
