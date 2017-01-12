# -*- encoding : UTF-8 -*-
class PreAssignmentDelivery < ActiveRecord::Base
  belongs_to :user
  belongs_to :report, class_name: 'Pack::Report'
  belongs_to :organization


  has_and_belongs_to_many :preseizures, class_name: 'Pack::Report::Preseizure'


  validates_presence_of   :pack_name, :number, :state
  validates_uniqueness_of :number


  before_validation :set_number

  scope :auto,         -> { where(is_auto: true) }
  scope :sent,         -> { where(state: 'sent') }
  scope :error,        -> { where(state: 'error') }
  scope :manual,       -> { where(is_auto: false) }
  scope :pending,      -> { where(state: 'pending') }
  scope :sending,      -> { where(state: 'sending') }
  scope :notified,     -> { where(is_notified: true) }
  scope :xml_built,    -> { where(state: 'xml_built') }
  scope :by_number,    -> { order(number: :desc) }
  scope :building_xml, -> { where(state: 'building_xml') }
  scope :not_notified, -> { where(is_to_notify: true, is_notified: [nil, false]) }


  state_machine initial: :pending do
    state :sent
    state :error
    state :pending
    state :sending
    state :xml_built
    state :building_xml

    event :building_xml do
      transition pending: :building_xml
    end

    event :xml_built do
      transition building_xml: :xml_built
    end

    event :sending do
      transition [:pending, :xml_built, :error] => :sending
    end

    event :sent do
      transition sending: :sent
    end

    event :error do
      transition [:building_xml, :sending] => :error
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


  def self.search(contains)
    deliveries = PreAssignmentDelivery.all

    deliveries = deliveries.where(state:         contains[:state])                             if contains[:state].present?
    deliveries = deliveries.where(is_auto:       contains[:is_auto].to_i == 1)                 if contains[:is_auto].present?
    deliveries = deliveries.where(created_at:    contains[:created_at])                        if contains[:created_at].present?
    deliveries = deliveries.where(total_item:    contains[:total_item].to_i)                   if contains[:total_item].present?
    deliveries = deliveries.where("pack_name LIKE ?", "%#{contains[:pack_name]}%")             if contains[:pack_name].present?
    deliveries = deliveries.where("error_message LIKE ?", "%#{contains[:error_message]}%")     if contains[:error_message].present?

    deliveries
  end

  private


  def set_number
    dba = DbaSequence.find_by_name('preassignment_delivery')

    counter = dba.counter  + 1

    dba.update(counter: counter)

    self.number = counter
  end
end
