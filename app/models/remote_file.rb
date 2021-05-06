# -*- encoding : UTF-8 -*-
class RemoteFile < ApplicationRecord
  DROPBOX          = 'Dropbox'.freeze
  DROPBOX_EXTENDED = 'Dropbox Extended'.freeze
  GOOGLE_DRIVE     = 'Google Drive'.freeze
  FTP              = 'FTP'.freeze
  SFTP             = 'SFTP'.freeze
  BOX              = 'Box'.freeze
  KNOWINGS         = 'Knowings'.freeze
  MY_COMPANY_FILES = 'My Company Files'.freeze
  SERVICE_NAMES    = [DROPBOX, DROPBOX_EXTENDED, GOOGLE_DRIVE, FTP, SFTP, BOX, KNOWINGS, MY_COMPANY_FILES].freeze

  belongs_to :user, optional: true
  belongs_to :pack, optional: true
  belongs_to :group, optional: true
  belongs_to :remotable, polymorphic: true
  belongs_to :organization, optional: true


  has_and_belongs_to_many :preseizures, class_name: 'Pack::Report::Preseizure', association_foreign_key: 'pack_report_preseizure_id'


  validates_presence_of  :state
  validates_presence_of  :service_name
  validates_inclusion_of :service_name, in: SERVICE_NAMES


  scope :of,               -> (object, service_name) { where('user_id = ? OR group_id = ? OR organization_id = ?', object.id, object.id, object.id).where(service_name: service_name) }
  scope :waiting,          -> { where(state: :waiting) }
  scope :sending,          -> { where(state: :sending) }
  scope :cancelled,        -> { where(state: :cancelled) }
  scope :processed,        -> { where(state: [:synced, :cancelled]) }
  scope :retryable,        -> { where("tried_count < ?", 2) }
  scope :of_service,       -> (service_name) { where(service_name: service_name) }
  scope :synchronized,     -> { where(state: :synced) }
  scope :not_retryable,    -> { where("tried_count >= ?", 2) }
  scope :not_processed,    -> { where.not(state: [:synced, :cancelled, :sending]) }
  scope :with_extension,   -> (extension) { where(extension: extension) }
  scope :not_synchronized, -> { where(state: :not_synced) }
  scope :with,             -> (period) { where(updated_at: period) }


  after_create  :update_pack
  after_save    :update_pack
  after_destroy :update_pack


  def self.cancel_all
    update_all(state:         'cancelled',
               tried_at:      nil,
               tried_count:   0,
               error_message: '')
  end


  def waiting!
    self.state = 'waiting'

    reset

    save
  end


  def cancel!
    self.state = 'cancelled'
    self.tried_count = 0

    reset

    save
  end


  def sending!(rpath = '')
    self.state         = 'sending'
    self.path          = rpath
    self.error_message = ''
    self.tried_at      = nil

    save
  end


  def synced!
    if temp_path.present? && File.exist?(temp_path)
      if extension == KnowingsApi::File::EXTENSION
        dir = File.dirname(temp_path)
        FileUtils.remove_entry File.join(dir, 'meta.xml')
      end
      FileUtils.remove_entry temp_path
    end

    self.state = 'synced'
    self.tried_count = 0

    set_tried_at
    save
  end


  def not_synced!(message = '')
    self.state = 'not_synced'
    self.tried_count += 1
    begin
      self.error_message = message.to_s
      set_tried_at
      save
    rescue
      self.error_message = 'unknown service error'
      set_tried_at
      save
    end
  end

  def not_retryable!(message = '')
    self.state         = 'not_synced'
    self.tried_count   = 2
    begin
      self.error_message = message.to_s
      set_tried_at
      save
    rescue
      self.error_message = 'unknown service error'
      set_tried_at
      save
    end
  end

  def name
    if remotable.class == Pack::Piece && (pack.organization.foc_file_naming_policy.scope == 'organization' || group.present? || user.is_prescriber)
      name_part = remotable.name.split

      options = {
        period:       name_part[2],
        journal:      name_part[1],
        extension:    extension,
        user_code:    pack.owner.code,
        user_company: pack.owner.company,
        piece_number: "%0#{DataProcessor::TempPack::POSITION_SIZE}d" % name_part[3].to_i
      }

      if (preseizure = remotable.preseizures.first)
        options.merge!(third_party:    preseizure.third_party.presence,
                       invoice_number: preseizure.piece_number.presence,
                       invoice_date:   preseizure.date.try(:to_date).try(:to_s).presence)
      end

      CustomUtils.customize_file_name(pack.organization.foc_file_naming_policy, options)
    else
      local_name
    end
  end


  def basename
    File.basename(path, '.*')
  end


  def local_path
    temp_path.presence || remotable.cloud_content_object.path
  end


  def local_name
    File.basename(local_path)
  rescue
    nil
  end


  def pack_name
    pack.name.tr(' ', '_')
  end


  def local_size
    File.size(local_path)
  rescue
    nil
  end


  def at
    if state == 'synced'
      "at #{tried_at}"
    elsif state == 'not_synced'
      "at #{tried_at} with error : #{error_message}"
    else
      ''
    end
  end


  def formated_service_name
    blank_size = 16 - service_name.size
    blank_size = 0 if blank_size < 0

    "[#{service_name}" + (' ' * blank_size) + ']'
  end


  def formated_state
    blank_size = 10 - state.size
    blank_size = 0 if blank_size < 0

    "[#{state}" + (' ' * blank_size) + ']'
  end


  def to_s
    if state.in? %w(waiting cancelled)
      "#{formated_service_name}#{formated_state} #{name}"
    else
      "#{formated_service_name}#{formated_state} #{path} #{at}"
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
    end
  end

  def receiver_info
    case receiver.class.name
    when User.name
      if receiver.collaborator?
        if receiver.memberships.count == 1
          receiver.memberships.first.code
        else
          receiver.memberships.where(organization_id: pack.organization_id).first.code
        end
      else
        receiver.code
      end
    when Group.name
      "#{receiver.organization.code}/#{receiver.name}"
    when Organization.name
      receiver.code
    end
  end

  protected


  def reset
    reset_tried_at

    self.tried_count = 0
    self.error_message = ''
  end


  def reset_tried_at
    self.tried_at = nil
  end


  def set_tried_at
    self.tried_at = Time.now
  end


  def update_pack
    pack.update_attribute(:remote_files_updated_at, Time.now) if pack
  end
end
