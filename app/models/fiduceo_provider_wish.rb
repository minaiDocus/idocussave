# -*- encoding : UTF-8 -*-
class FiduceoProviderWish
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  attr_accessor :password, :custom_connection_info

  field :state, default: 'pending'
  field :name
  field :url,   default: 'http://www.example.com'
  field :login
  field :description

  field :message
  field :notified_at,   type: Time
  field :processing_at, type: Time

  validates_presence_of :name, :url, :login, :description
  validates_presence_of :password, if: lambda { |e| !e.persisted? }

  scope :pending,                 where(state: 'pending')
  scope :processing,              where(state: 'processing')
  scope :rejected,                where(state: 'rejected')
  scope :accepted,                where(state: 'accepted')
  scope :processed,               where(:state.in => [:rejected, :accepted])
  scope :notified,                where(:notified_at.nin => [nil])
  scope :not_notified,            where(notified_at: nil)
  scope :not_processed_or_recent, where('$or' => [{ :state.in => %w(pending processing) }, { :state.in => %w(rejected accepted), :updated_at.gte => 1.month.ago }])

  state_machine :initial => :pending do
    state :pending
    state :processing
    state :rejected
    state :accepted

    before_transition any => :processing do |provider_wish, transition|
      provider_wish.processing_at = Time.now
    end

    event :start_process do
      transition :pending => :processing
    end

    event :reject do
      transition [:pending, :processing] => :rejected
    end

    event :accept do
      transition :processing => :accepted
    end
  end

  def is_notified?
    notified_at.present?
  end

  class << self
    def deliver_mails
      users = User.find FiduceoProviderWish.processed.not_notified.distinct(:user_id)
      users.each do |user|
        deliver_mail(user)
      end
    end

    def deliver_mail(user)
      accepted = user.fiduceo_provider_wishes.accepted.not_notified
      rejected = user.fiduceo_provider_wishes.rejected.not_notified
      if accepted.any? || rejected.any?
        processing = user.fiduceo_provider_wishes.processing
        FiduceoProviderWishMailer.notify(user, accepted, rejected, processing).deliver
        accepted.update_all(notified_at: Time.now) if accepted.any?
        rejected.update_all(notified_at: Time.now) if rejected.any?
      end
    end
  end
end
