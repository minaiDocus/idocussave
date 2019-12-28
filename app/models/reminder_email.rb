# -*- encoding : UTF-8 -*-
class ReminderEmail < ApplicationRecord
  serialize :delivered_user_ids, Array
  serialize :processed_user_ids, Array

  belongs_to :organization


  validates_presence_of  :name, :subject, :content, :organization_id
  validates_inclusion_of :period, in: [1, 3]
  validates_inclusion_of :delivery_day, in: 0..31


  def deliver
    clients = organization.customers.active - processed_users

    clients = clients.select do |client|
      begin
        client.subscription.period_duration == period
      rescue
        false
      end
    end

    if clients.any?
      clients.each do |client|
        if client.notify.to_send_docs && client.options.is_upload_authorized
          period = client.periods.order(start_date: :desc).first
          if period
            packs_delivered = client.packs.where("created_at > ?", period.start_date).scan_delivered.count
          else
            packs_delivered = 0
          end

          if packs_delivered == 0
            ReminderMailer.remind(self, client).deliver_later

            delivered_user_ids << client.id

            save
          end
        end

        processed_user_ids << client.id

        save
      end

      update(delivered_at: Time.now)
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
    User.where(id: processed_user_ids)
  end


  def delivered_users
    User.where(id: delivered_user_ids)
  end


  def deliver_if_its_time
    if is_time_to_deliver?
      init if delivered_at.present? && end_of_period < Time.now
      deliver
    end
  end


  def is_time_to_deliver?
    (end_of_period.nil? || end_of_period < Time.now) && delivery_day == Time.now.day
  end


  def end_of_period
    if delivered_at
      if period == 1
        delivered_at.end_of_month
      elsif period == 3
        delivered_at.end_of_quarter
      end
    end
  end


  def self.deliver
    all.each(&:deliver_if_its_time)
  end
end
