# -*- encoding : UTF-8 -*-
module GoogleDrive
  class << self
    attr_reader :config
  end


  def self.configure
    yield config
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.config=(new_config)
    config.client_id              = new_config['client_id']              if new_config['client_id']
    config.client_secret          = new_config['client_secret']          if new_config['client_secret']

    config.scope                  = new_config['scope']                  if new_config['scope']
    config.access_type            = new_config['access_type']            if new_config['access_type']
    config.approval_prompt        = new_config['approval_prompt']        if new_config['approval_prompt']
    config.include_granted_scopes = new_config['include_granted_scopes'] if new_config['include_granted_scopes']
  end
end
