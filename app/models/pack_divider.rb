# -*- encoding : UTF-8 -*-
class PackDivider < ApplicationRecord
  self.inheritance_column = :_type_disabled


  belongs_to :pack, inverse_of: :dividers


  validates_presence_of  :name, :type, :origin, :pages_number, :position
  validates_inclusion_of :type, within: %w(sheet piece)
  validates_inclusion_of :origin, within: %w(scan upload dematbox_scan retriever)

  scope :sheets,           -> { where(type: 'sheet') }
  scope :covers,           -> { where(is_a_cover: true) }
  scope :pieces,           -> { where(type: 'piece') }
  scope :scanned,          -> { where(origin: 'scan') }
  scope :retrieved,        -> { where(origin: 'retriever') }
  scope :uploaded,         -> { where(origin: 'upload') }
  scope :not_covers,       -> { where(is_a_cover: false) }
  scope :dematbox_scanned, -> { where(origin: 'dematbox_scan') }
  scope :by_position,      -> { order(position: :asc) }

  scope :of_period, lambda { |time, duration|
    case duration
    when 1
      start_at = time.beginning_of_month
      end_at   = time.end_of_month
    when 3
      start_at = time.beginning_of_quarter
      end_at   = time.end_of_quarter
    when 12
      start_at = time.beginning_of_year
      end_at   = time.end_of_year
    end
    where('created_at >= ? AND created_at <= ?', start_at, end_at)
  }

  class << self
    def last
      order(position: :desc).first
    end
  end
end
