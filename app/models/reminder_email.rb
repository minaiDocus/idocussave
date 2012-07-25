# -*- encoding : UTF-8 -*-
class ReminderEmail
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :user
  
  field :name, :type => String
  field :subject, :type => String
  field :content, :type => String
  field :delivery_day, :type => Integer, :default => 1
  field :delivered_at, :type => Time
  field :delivered_user_ids, :type => Array, :default => []
  field :processed_user_ids, :type => Array, :default => []
  
  validates_presence_of :name, :subject, :content, :user_id
  
  def deliver
    clients = user.clients.active - processed_users
    unless clients.empty?
      clients.each do |client|
        if client != user
          now = Time.now
          name = "#{client.code} #{now.year}#{now.month} all"
          packs_delivered = client.own_packs.where(:name => name).scan_delivered.count
          if packs_delivered == 0
            ReminderMailer.remind(self,client).deliver
            delivered_user_ids << client.id
            save
          end
          processed_user_ids << client.id
          save
        end
      end
      self.update_attributes(:delivered_at => Time.now)
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
    User.any_in(:_id => processed_user_ids)
  end
  
  def delivered_users
    User.any_in(:_id => delivered_user_ids)
  end
  
  def deliver_if_its_time
    if ((delivered_at.nil? || delivered_at.month < Time.now.month) and Time.now.day == delivery_day)
      self.init if !delivered_at.nil? and delivered_at.month < Time.now.month
      deliver
    end
  end
  
  def self.deliver
    self.all.entries.each do |reminder_email|
      reminder_email.deliver_if_its_time
    end
  end
end
