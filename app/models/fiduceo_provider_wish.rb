# -*- encoding : UTF-8 -*-
### Fiduceo related - remained untouched (or nearly) : to be deprecated soon ###
class FiduceoProviderWish < ActiveRecord::Base
  belongs_to :user

  attr_accessor :password, :custom_connection_info


  validates_presence_of :name, :url, :login, :description
  validates_presence_of :password, if: ->(e) { !e.persisted? }


  scope :pending,                 -> { where(state: 'pending') }
  scope :processing,              -> { where(state: 'processing') }
  scope :rejected,                -> { where(state: 'rejected') }
  scope :accepted,                -> { where(state: 'accepted') }
  scope :processed,               -> { where(state: [:rejected, :accepted]) }
  scope :notified,                -> { where.not(notified_at: [nil]) }
  scope :not_notified,            -> { where(notified_at: nil) }
  scope :not_processed_or_recent, -> { where('state IN (?) OR (state IN (?) AND updated_at >= ?)', %w(pending processing), %w(rejected accepted), 1.month.ago) }
  scope :not_processed,           -> { where(state: [:pending, :processing]) }



  state_machine initial: :pending do
    state :pending
    state :processing
    state :rejected
    state :accepted

    before_transition any => :processing do |provider_wish, _transition|
      provider_wish.processing_at = Time.now
    end

    event :start_process do
      transition pending: :processing
    end

    event :reject do
      transition [:pending, :processing] => :rejected
    end

    event :accept do
      transition processing: :accepted
    end
  end


  before_create do |provider_wish|
    client = Fiduceo::Client.new provider_wish.user.fiduceo_id
    params = {
      name:                   provider_wish.name,
      url:                    provider_wish.url,
      login:                  provider_wish.login,
      pass:                   provider_wish.password,
      custom_connection_info: provider_wish.custom_connection_info,
      description:            provider_wish.description
    }
    client.put_provider_wish params
  end


  def is_notified?
    notified_at.present?
  end


  def self.deliver_mails
    users = User.find FiduceoProviderWish.processed.not_notified.distinct(:user_id)
    users.each do |user|
      deliver_mail(user)
    end
  end

  def self.deliver_mail(user)
    accepted = user.fiduceo_provider_wishes.accepted.not_notified
    rejected = user.fiduceo_provider_wishes.rejected.not_notified
    if accepted.any? || rejected.any?
      processing = user.fiduceo_provider_wishes.processing
      FiduceoProviderWishMailer.notify(user, accepted, rejected, processing).deliver_later
      accepted.update_all(notified_at: Time.now) if accepted.any?
      rejected.update_all(notified_at: Time.now) if rejected.any?
    end
  end


  def self.search
    provider_wishes = FiduceoProviderWish.all

    user_ids = []

    if params[:user_contains] && params[:user_contains][:code].present?
      user_ids = User.where("code LIKE ?", "%#{params[:user_contains][:code]}%").distinct(:id)
    end

    provider_wishes = provider_wishes.where("url LIKE ?", "%#{contains[:url]}%")     unless contains[:url].blank?
    provider_wishes = provider_wishes.where("name LIKE ?", "%#{contains[:name]}%")   unless contains[:name].blank?
    provider_wishes = provider_wishes.where("login LIKE ?", "%#{contains[:login]}%") unless contains[:login].blank?
    provider_wishes = provider_wishes.where(state:         contains[:state])         unless contains[:state].blank?
    provider_wishes = provider_wishes.where(user_id:      user_ids)                  if user_ids.any?
    provider_wishes = provider_wishes.where(created_at:    contains[:created_at])    unless contains[:created_at].blank?
    provider_wishes = provider_wishes.where(updated_at:    contains[:updated_at])    unless contains[:updated_at].blank?
    provider_wishes = provider_wishes.where(notified_at:   contains[:notified_at])   unless contains[:notified_at].blank?
    provider_wishes = provider_wishes.where(processing_at: contains[:processing_at]) unless contains[:processing_at].blank?

    if contains[:is_notified]
      if contains[:is_notified].to_i == 1
        provider_wishes = provider_wishes.notified
      elsif contains[:is_notified].to_i == 0
        provider_wishes = provider_wishes.not_notified
      end
    end

    provider_wishes
  end


  def self.search_for_collection(collection, contains)
    collection = collection.where("name LIKE ?", "%#{contains[:name]}%") unless contains[:name].blank?

    collection
  end
end
