# -*- encoding : UTF-8 -*-
class Knowings
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :organization

  field :username,  type: String
  field :password,  type: String
  field :url,       type: String
  field :is_active, type: Boolean, default: true
  field :state,     type: String,  default: 'not_performed'

  field :is_third_party_included,          type: Boolean, default: false
  field :is_pre_assignment_state_included, type: Boolean, default: false

  validates_presence_of :username, :if => :active?
  validates_presence_of :password, :if => :active?
  validates_presence_of :url,      :if => :active?

  validates_url :url, :allow_blank => true, :message => I18n.t('activemodel.errors.messages.invalid')

  state_machine :state, :initial => :not_performed, :namespace => 'configuration' do
    state :not_performed
    state :verifying
    state :invalid
    state :valid

    after_transition :on => :verify do |knowings|
      knowings.process_verification
    end

    event :reinit do
      transition all => :not_performed
    end

    event :verify do
      transition [:invalid, :not_performed] => :verifying
    end

    event :invalid do
      transition all => :invalid
    end

    event :valid do
      transition all => :valid
    end
  end

  def active?
    self.is_active
  end

  def is_configured?
    configuration_valid?
  end

  def configuration_changed?
    username_changed? || password_changed? || url_changed? || is_active_changed?
  end

  def client
    @client ||= KnowingsApi::Client.new(self.username, self.password, self.url)
  end

  def process_verification
    if client.verify
      valid_configuration
    else
      invalid_configuration
    end
  end
  handle_asynchronously :process_verification, queue: 'knowings access verification', priority: 0

  def sync(remote_files, log=Logger.new(STDOUT))
    remote_files.each_with_index do |remote_file,index|
      remote_filepath = File.join(self.url, remote_file.local_name)
      tries = 0
      begin
        remote_file.sending!(remote_filepath)
        number = "\t[#{'%0.3d' % (index+1)}]"
        info = "#{number}[#{tries+1}] \"#{remote_filepath}\""
        result = client.put(remote_file.local_path, remote_file.local_name)
        raise UnexpectedResponseCode.new result unless result.in? [200, 201]
        log.info { "#{info} uploaded" }
        remote_file.synced!
      rescue => e
        tries += 1
        log.info { "#{info} upload failed : [#{e.class}] #{e.message}" }
        if tries < 3
          retry
        else
          log.info { "#{number} retrying later" }
          remote_file.not_synced!("[#{e.class}] #{e.message}")
        end
      end
    end
  end

  class UnexpectedResponseCode < RuntimeError; end
end
