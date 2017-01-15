# -*- encoding : UTF-8 -*-
class NewProviderRequest < ActiveRecord::Base
  belongs_to :user

  attr_accessor :edited_by_customer

  # TODO encrypt password field

  validates_presence_of :name, :url
  validates_presence_of :password, :types, if: :edited_by_customer
  validate :presence_of_login

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

    before_transition any => :processing do |request, transition|
      request.processing_at = Time.now
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

  def is_notified?
    notified_at.present?
  end

  class << self
    def deliver_mails
      users = User.find NewProviderRequest.processed.not_notified.distinct(:user_id)
      users.each do |user|
        deliver_mail(user)
      end
    end

    def deliver_mail(user)
      accepted = user.new_provider_requests.accepted.not_notified
      rejected = user.new_provider_requests.rejected.not_notified
      if accepted.any? || rejected.any?
        processing = user.new_provider_requests.processing
        NewProviderRequestMailer.notify(user, accepted, rejected, processing).deliver
        accepted.update_all(notified_at: Time.now) if accepted.any?
        rejected.update_all(notified_at: Time.now) if rejected.any?
      end
    end

    def search
      new_provider_requests = NewProviderRequest.all

      user_ids = []

      if params[:user_contains] && params[:user_contains][:code].present?
        user_ids = User.where("code LIKE ?", "%#{params[:user_contains][:code]}%").distinct(:id)
      end

      new_provider_requests = new_provider_requests.where("url LIKE ?",   "%#{contains[:url]}%")   unless contains[:url].blank?
      new_provider_requests = new_provider_requests.where("name LIKE ?",  "%#{contains[:name]}%")  unless contains[:name].blank?
      new_provider_requests = new_provider_requests.where("login LIKE ?", "%#{contains[:login]}%") unless contains[:login].blank?
      new_provider_requests = new_provider_requests.where(state:         contains[:state])         unless contains[:state].blank?
      new_provider_requests = new_provider_requests.where(user_id:       user_ids)                 if user_ids.any?
      new_provider_requests = new_provider_requests.where(created_at:    contains[:created_at])    unless contains[:created_at].blank?
      new_provider_requests = new_provider_requests.where(updated_at:    contains[:updated_at])    unless contains[:updated_at].blank?
      new_provider_requests = new_provider_requests.where(notified_at:   contains[:notified_at])   unless contains[:notified_at].blank?
      new_provider_requests = new_provider_requests.where(processing_at: contains[:processing_at]) unless contains[:processing_at].blank?

      if contains[:is_notified]
        if contains[:is_notified].to_i == 1
          new_provider_requests = new_provider_requests.notified
        elsif contains[:is_notified].to_i == 0
          new_provider_requests = new_provider_requests.not_notified
        end
      end

      new_provider_requests
    end

    def search_for_collection(collection, contains)
      collection = collection.where("name LIKE ?", "%#{contains[:name]}%") unless contains[:name].blank?

      collection
    end
  end

private

  def presence_of_login
    unless email.present? || login.present?
      errors.add(:email, :blank)
      errors.add(:login, :blank)
    end
  end
end
