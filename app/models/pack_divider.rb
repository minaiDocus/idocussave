# -*- encoding : UTF-8 -*-
class PackDivider
  include Mongoid::Document
  include Mongoid::Timestamps
  
  belongs_to :pack, inverse_of: :dividers
  
  field :name
  field :type
  field :origin
  field :is_a_cover,   type: Boolean, default: false
  field :pages_number, type: Integer
  field :position,     type: Integer

  validates_presence_of  :name, :type, :origin, :pages_number, :position
  validates_inclusion_of :type, within: %w(sheet piece)
  validates_inclusion_of :origin, within: %w(scan upload dematbox_scan)

  index :type
  index :origin
  index :is_a_cover
  
  scope :uploaded,         where: { origin: 'upload' }
  scope :scanned,          where: { origin: 'scan' }
  scope :dematbox_scanned, where: { origin: 'dematbox_scan' }
  scope :sheets,           where: { type: 'sheet' }
  scope :pieces,           where: { type: 'piece' }
  scope :of_month,         lambda { |time| where(created_at: { '$gte' => time.beginning_of_month, '$lte' => time.end_of_month }) }

  scope :covers,     where: { is_a_cover: true }
  scope :not_covers, where: { is_a_cover: false }

  class << self
    def by_position
      asc(:position)
    end

    def last
      desc(:position).first
    end
  end
end
