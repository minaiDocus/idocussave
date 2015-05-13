# -*- encoding : UTF-8 -*-
class RemoteFile
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  belongs_to :pack
  belongs_to :organization
  belongs_to :group
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

  index({ state: 1 })
  index({ service_name: 1 })
  index({ tried_count: 1 })

  validates_presence_of :state
  validates_presence_of :service_name
  validates_inclusion_of :service_name, in: ExternalFileStorage::SERVICES

  scope :of, -> object, service_name { any_of({ user_id: object.id }, { group_id: object.id }, { organization_id: object.id }).where(service_name: service_name) }
  scope :of_service, -> service_name { where(service_name: service_name) }
  scope :with_extension, -> extension { where(extension: extension) }

  scope :waiting,    -> { where(state: :waiting) }
  scope :cancelled,  -> { where(state: :cancelled) }
  scope :sending,    -> { where(state: :sending) }
  scope :synced,     -> { where(state: :synced) }
  scope :not_synced, -> { where(state: :not_synced) }

  scope :processed,     -> { any_in(state: [:synced,:cancelled]) }
  scope :not_processed, -> { not_in(state: [:synced,:cancelled]) }

  scope :retryable,     -> { where(:tried_count.lt => 2) }
  scope :not_retryable, -> { where(:tried_count.gte => 2) }

  def self.cancel_all
    update_all state:         'cancelled',
               tried_count:   0,
               tried_at:      nil,
               error_message: ''
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
    self.state         = 'sending'
    self.path          = rpath
    self.error_message = ''
    self.tried_at      = nil
    save
  end

  def synced!
    if temp_path.present? && File.exists?(temp_path)
      if extension == KnowingsApi::File::EXTENSION
        dir = File.dirname(temp_path)
        FileUtils.remove_entry File.join(dir, 'meta.xml')
      end
      FileUtils.remove_entry temp_path
    end
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
    if remotable && remotable.class.name == Pack::Piece.name && pack.organization.is_file_naming_policy_active
      part = remotable.name.split
      result = pack.organization.file_naming_policy.
        gsub(':customerCode', part[0].sub(/.*%/,'')).
        gsub(':journal',      part[1]).
        gsub(':position',     "%0#{DocumentProcessor::POSITION_SIZE}d" % part[3].to_i)
      if remotable.try(:preseizures).try(:any?)
        preseizure = remotable.preseizures.first
        result = result.gsub(':thirdParty', preseizure.third_party.to_s).
          gsub(':date',   preseizure.date.try(:to_date).try(:to_s)).
          gsub(':period', [part[2][0..3], part[2][4..5]].join('-'))
      else
        result = result.gsub(':thirdParty', '').
          gsub(':date',   '').
          gsub(':period', [part[2][0..3], part[2][4..5]].join)
      end
      result + '.pdf'
    else
      local_name
    end
  end

  def basename
    File.basename(path,'.*')
  end

  def local_path
    temp_path.presence || remotable.content.path
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

  def receiver
    user || group || organization
  end

  def receiver=(object)
    if object.class.name == User.name
      self.user = object
    elsif object.class.name == Group.name
      self.group = object
    elsif object.class.name == Organization.name
      self.organization = object
    else
      nil
    end
  end

  protected

  def reset
    reset_tried_at
    self.tried_count = 0
    self.error_message = ""
  end

  def reset_tried_at
    self.tried_at = nil
  end

  def set_tried_at
    self.tried_at = Time.now
  end
end
