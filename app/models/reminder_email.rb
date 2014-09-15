# -*- encoding : UTF-8 -*-
class ReminderEmail
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization

  field :name,               type: String
  field :subject,            type: String
  field :content,            type: String
  field :delivery_day,       type: Integer, default: 1
  field :period,             type: Integer, default: 1
  field :delivered_at,       type: Time
  field :delivered_user_ids, type: Array,   default: []
  field :processed_user_ids, type: Array,   default: []

  validates_presence_of :name, :subject, :content, :organization_id
  validates_inclusion_of :period, in: [1,3]
  validates_inclusion_of :delivery_day, in: 0..31

  def deliver
    clients = organization.customers.active - processed_users
    clients = clients.select do |client|
      client.scan_subscriptions.current.period_duration == self.period rescue false
    end
    if clients.any?
      clients.each do |client|
        if client.is_reminder_email_active
          now = Time.now
          name = "#{client.code} #{now.year}#{now.month} all"
          period = client.periods.last
          if period
            packs_delivered = client.own_packs.where(name: name, :created_at.gt => period.start_at).scan_delivered.count
          else
            packs_delivered = 0
          end
          if packs_delivered == 0
            ReminderMailer.remind(self,client).deliver
            delivered_user_ids << client.id
            save
          end
        end
        processed_user_ids << client.id
        save
      end
      self.update_attributes(delivered_at: Time.now)
    else
      clients
    end
  end

  def init
    self.delivered_user_ids = []
    self.processed_user_ids = []
    self.delivered_at = nil
    save
  end

  def processed_users
    User.any_in(_id: processed_user_ids)
  end

  def delivered_users
    User.any_in(_id: delivered_user_ids)
  end

  def deliver_if_its_time
    if is_time_to_deliver?
      init if self.delivered_at.present? && end_of_period < Time.now
      deliver
    end
  end

  def is_time_to_deliver?
    (end_of_period.nil? or end_of_period < Time.now) && self.delivery_day == Time.now.day
  end

  def end_of_period
    if self.delivered_at
      if self.period == 1
        self.delivered_at.end_of_month
      elsif self.period == 3
        self.delivered_at.end_of_quarter
      end
    else
      nil
    end
  end

  def self.deliver
    self.all.entries.each do |reminder_email|
      reminder_email.deliver_if_its_time
    end
  end
end
