# -*- encoding : UTF-8 -*-
class PreAssignmentDelivery
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization
  belongs_to :report, class_name: 'Pack::Report'
  belongs_to :user
  has_and_belongs_to_many :preseizures, class_name: 'Pack::Report::Preseizure'

  field :pack_name
  field :number
  field :state
  field :is_auto,      type: Boolean
  field :total_item,   type: Integer
  field :ibiza_id
  field :grouped_date, type: Date
  field :xml_data
  field :error_message
  field :is_to_notify, type: Boolean
  field :is_notified,  type: Boolean
  field :notified_at,  type: Time

  validates_presence_of :pack_name, :number, :state
  validates_uniqueness_of :number

  index({ number: 1 }, { unique: true })
  index({ state: 1 })
  index({ is_auto: 1 })
  index({ total_item: 1 })
  index({ is_to_notify: 1 })
  index({ is_notified: 1 })

  before_validation :set_number

  scope :by_number, -> { desc(:number) }

  scope :auto,   -> { where(is_auto: true) }
  scope :manual, -> { where(is_auto: false) }

  scope :pending,      -> { where(state: 'pending') }
  scope :building_xml, -> { where(state: 'building_xml') }
  scope :xml_built,    -> { where(state: 'xml_built') }
  scope :sending,      -> { where(state: 'sending') }
  scope :sent,         -> { where(state: 'sent') }
  scope :error,        -> { where(state: 'error') }

  scope :notified,     -> { where(is_notified: true) }
  scope :not_notified, -> { where(is_to_notify: true, :is_notified.in => [nil, false]) }

  state_machine :initial => :pending do
    state :pending
    state :building_xml
    state :xml_built
    state :sending
    state :sent
    state :error

    event :building_xml do
      transition :pending => :building_xml
    end

    event :xml_built do
      transition :building_xml => :xml_built
    end

    event :sending do
      transition [:pending, :xml_built, :error] => :sending
    end

    event :sent do
      transition :sending => :sent
    end

    event :error do
      transition [:building_xml, :sending] => :error
    end
  end

  class << self
    def find_by_number(number)
      where(number: number.to_i).first
    end
  end
  
  def ibiza
    @ibiza ||= organization.ibiza
  end

  def ibiza_access_token
    if ibiza.two_channel_delivery?
      preseizures.first.operation.present? ? ibiza.access_token_2 : ibiza.access_token
    else
      ibiza.practical_access_token
    end
  end

private

  def set_number
    self.number = DbaSequence.next(:preassignment_delivery) unless self.number
  end
end
