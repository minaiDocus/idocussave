# -*- encoding : UTF-8 -*-
class RemoteFile
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  belongs_to :pack
  belongs_to :remotable, polymorphic: true

  field :path,          type: String, default: ''
  field :temp_path,     type: String, default: ''
  field :extension,     type: String, default: '.pdf'
  field :size,          type: Integer
  field :tried_at,      type: Time
  field :state,         type: String, default: 'waiting'
  field :service_name,  type: String
  field :error_message, type: String
  field :tried_count,   type: Integer, default: 0

  validates_presence_of :state
  validates_presence_of :service_name
  validates_inclusion_of :service_name, in: ExternalFileStorage::SERVICES

  scope :of, lambda { |user,service_name| where(user_id: user.id, service_name: service_name) }
  scope :of_service, lambda { |service_name| where(service_name: service_name) }
  scope :with_extension, lambda { |extension| where(extension: extension) }

  scope :waiting,    where: { state: :waiting }
  scope :cancelled,  where: { state: :cancelled }
  scope :sending,    where: { state: :sending }
  scope :synced,     where: { state: :synced }
  scope :not_synced, where: { state: :not_synced }

  scope :processed,     any_in: { state: [:synced,:cancelled] }
  scope :not_processed, not_in: { state: [:synced,:cancelled] }

  scope :retryable,     where: { :tried_count.lt => 10 }
  scope :not_retryable, where: { :tried_count.gte => 10 }

  def self.reset_all_tried_count!
    all.each do |remote_file|
      remote_file.tried_count = 0
      remote_file.save
    end
  end

  def self.cancel_all!
    all.each do |remote_file|
      remote_file.cancel!
      remote_file.save
    end
  end

  def waiting!
    self.state = "waiting"
    reset
    save
  end

  def cancel!
    self.state = "cancelled"
    self.tried_count = 0
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
    self.tried_count = 0
    set_tried_at
    save
  end

  def not_synced!(message='')
    self.state = "not_synced"
    self.tried_count += 1
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
    current_path = remotable.content.path rescue
    current_path || self.temp_path
  end

  def local_name
    File.basename(local_path) rescue nil
  end

  def pack_name
    self.pack.name.gsub(' ','_')
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
    blank_size = 16 - self.service_name.size
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
