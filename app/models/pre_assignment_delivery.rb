# -*- encoding : UTF-8 -*-
class PreAssignmentDelivery < ApplicationRecord
  ATTACHMENTS_URLS={'cloud_content' => '/admin/deliveries'}

  belongs_to :user
  belongs_to :report, class_name: 'Pack::Report'
  belongs_to :organization

  has_one_attached :cloud_content

  has_and_belongs_to_many :preseizures, class_name: 'Pack::Report::Preseizure'

  validates_inclusion_of  :deliver_to, in: %w(ibiza exact_online my_unisoft)
  validates_presence_of   :pack_name, :state

  scope :ibiza,         -> { where(deliver_to: 'ibiza') }
  scope :exact_online,  -> { where(deliver_to: 'exact_online') }
  scope :my_unisoft,    -> { where(deliver_to: 'my_unisoft') }
  scope :auto,          -> { where(is_auto: true) }
  scope :sent,          -> { where(state: 'sent') }
  scope :error,         -> { where(state: 'error') }
  scope :manual,        -> { where(is_auto: false) }
  scope :pending,       -> { where(state: 'pending') }
  scope :sending,       -> { where(state: 'sending') }
  scope :notified,      -> { where(is_notified: true) }
  scope :data_built,    -> { where(state: 'data_built') }
  scope :building_data, -> { where(state: 'building_data') }
  scope :not_notified,  -> { where(is_to_notify: true, is_notified: [nil, false]) }


  before_destroy do |delivery|
    delivery.cloud_content.purge
  end

  state_machine initial: :pending do
    state :sent
    state :error
    state :pending
    state :sending
    state :data_built
    state :building_data

    event :building_data do
      transition pending: :building_data
    end

    event :data_built do
      transition building_data: :data_built
    end

    event :sending do
      transition [:pending, :data_built, :error] => :sending
    end

    event :sent do
      transition sending: :sent
    end

    event :error do
      transition [:building_data, :sending] => :error
    end
  end


  def cloud_content_object
    CustomActiveStorageObject.new(self, :cloud_content)
  end

  #this method is required to avoid custom_active_storage bug when seeking for paperclip equivalent method
  def content
    object = FakeObject.new
  end

  def ibiza
    @ibiza ||= organization.ibiza
  end

  def human_form_of_deliver_to
    case self.deliver_to
      when 'ibiza'
        'Ibiza'
      when 'exact_online'
        'Exact Online'
    end
  end

  def ibiza_access_token
    if ibiza.two_channel_delivery?
      if preseizures.first.operation.present?
        ibiza.access_token_2 if ibiza.second_configured?
      elsif ibiza.first_configured?
        ibiza.access_token
      end
    else
      ibiza.practical_access_token
    end
  end

  def self.search(contains)
    deliveries = PreAssignmentDelivery.all

    deliveries = deliveries.where(id:            contains[:id].to_i)                           if contains[:id].present?
    deliveries = deliveries.where(state:         contains[:state])                             if contains[:state].present?
    deliveries = deliveries.where(is_auto:       contains[:is_auto].to_i == 1)                 if contains[:is_auto].present?
    deliveries = deliveries.where(total_item:    contains[:total_item].to_i)                   if contains[:total_item].present?
    deliveries = deliveries.where("pack_name LIKE ?", "%#{contains[:pack_name]}%")             if contains[:pack_name].present?
    deliveries = deliveries.where("error_message LIKE ?", "%#{contains[:error_message]}%")     if contains[:error_message].present?

    if contains[:created_at]
      contains[:created_at].each do |operator, value|
        deliveries = deliveries.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    if contains[:updated_at]
      contains[:updated_at].each do |operator, value|
        deliveries = deliveries.where("updated_at #{operator} ?", value) if operator.in?(['>=', '<='])
      end
    end

    deliveries
  end
end
