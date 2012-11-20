# -*- encoding : UTF-8 -*-
class RemoteFile
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :user
  referenced_in :pack
  referenced_in :remotable, polymorphic: true

  field :path,          type: String, default: ''
  field :size,          type: Integer
  field :tried_at,      type: Time
  field :state,         type: String, default: 'waiting'
  field :service_name,  type: String
  field :error_message, type: String

  validates_presence_of :state
  validates_presence_of :service_name
  validates_inclusion_of :service_name, in: ExternalFileStorage::SERVICES

  scope :of, lambda { |user,service_name| where(user_id: user.id, service_name: service_name) }

  scope :waiting,    where: { state: :waiting }
  scope :cancelled,  where: { state: :cancelled }
  scope :sending,    where: { state: :sending }
  scope :synced,     where: { state: :synced }
  scope :not_synced, where: { state: :not_synced }

  scope :processed,     any_in: { state: [:synced,:cancelled] }
  scope :not_processed, not_in: { state: [:synced,:cancelled] }

  def waiting!
    self.state = "waiting"
    reset
    save
  end

  def cancel!
    self.state = "cancelled"
    reset
    save
  end

  def sending!(rpath='')
    self.state = "sending"
    self.path = rpath
    reset
    save
  end

  def synced!
    self.state = "synced"
    set_tried_at
    save
  end

  def not_synced!(message='')
    self.state = "not_synced"
    self.error_message = message
    set_tried_at
    save
  end

  def name
    File.basename(path)
  end

  def basename
    File.basename(path,'.*')
  end

  def local_path
    remotable.content.path rescue nil
  end

  def local_name
    File.basename(local_path) rescue nil
  end

  def local_size
    File.size(local_path) rescue nil
  end

  def at
    if self.state == 'synced'
      "at #{self.tried_at}"
    elsif self.state == 'not_synced'
      "at #{self.tried_at} with error : #{self.error_message}"
    else
      ""
    end
  end

  def formated_service_name
    blank_size = 15 - self.service_name.size
    blank_size = 0 if blank_size < 0
    "[#{service_name}" + (" "*blank_size) + "]"
  end

  def formated_state
    blank_size = 10 - self.state.size
    blank_size = 0 if blank_size < 0
    "[#{state}" + (" "*blank_size) + "]"
  end

  def to_s
    if self.state.in? %w(waiting cancelled)
      "#{formated_service_name}#{formated_state} #{local_name}"
    else
      "#{formated_service_name}#{formated_state} #{self.path} #{self.at}"
    end
  end

  protected

  def reset
    reset_tried_at
    self.error_message = ""
  end

  def reset_tried_at
    self.tried_at = nil
  end

  def set_tried_at
    self.tried_at = Time.now
  end
end
