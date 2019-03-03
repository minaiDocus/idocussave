# -*- encoding : UTF-8 -*-
class NewProviderRequest < ApplicationRecord
  belongs_to :user

  attr_accessor :edited_by_customer

  attr_encrypted :url,         random_iv: true
  attr_encrypted :login,       random_iv: true
  attr_encrypted :description, random_iv: true
  attr_encrypted :message,     random_iv: true
  attr_encrypted :email,       random_iv: true
  attr_encrypted :types,       random_iv: true

  validates :encrypted_url,         symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_url.nil? }
  validates :encrypted_description, symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_description.nil? }
  validates :encrypted_message,     symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_message.nil? }
  validates :encrypted_email,       symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_email.nil? }
  validates :encrypted_types,       symmetric_encryption: true, unless: Proc.new { |r| r.encrypted_types.nil? }

  validates_presence_of :name, :url
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
      users = User.find NewProviderRequest.processed.not_notified.pluck(:user_id)
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

    def search(contains)
      new_provider_requests = NewProviderRequest.all

      user_ids = []

      if contains[:user_code] && contains[:user_code].present?
        user_ids = User.where("code LIKE ?", "%#{contains[:user_code]}%").pluck(:id)
      end

      new_provider_requests = new_provider_requests.where("name LIKE ?", "%#{contains[:name]}%") unless contains[:name].blank?
      new_provider_requests = new_provider_requests.where(state:         contains[:state])       unless contains[:state].blank?
      new_provider_requests = new_provider_requests.where(user_id:       user_ids)               if user_ids.any?

      if contains[:created_at]
        contains[:created_at].each do |operator, value|
          new_provider_requests = new_provider_requests.where("created_at #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      if contains[:updated_at]
        contains[:updated_at].each do |operator, value|
          new_provider_requests = new_provider_requests.where("updated_at #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      if contains[:notified_at]
        contains[:notified_at].each do |operator, value|
          new_provider_requests = new_provider_requests.where("notified_at #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      if contains[:processing_at]
        contains[:processing_at].each do |operator, value|
          new_provider_requests = new_provider_requests.where("processing_at #{operator} ?", value) if operator.in?(['>=', '<='])
        end
      end

      if contains[:is_notified]
        if contains[:is_notified].to_i == 1
          new_provider_requests = new_provider_requests.notified
        elsif contains[:is_notified].to_i == 0
          new_provider_requests = new_provider_requests.not_notified
        end
      end

      new_provider_requests
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
