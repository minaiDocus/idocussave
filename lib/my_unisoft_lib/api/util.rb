module MyUnisoftLib
  module Api
    class Util
      def self.configure
        yield config
      end

      def self.config
        @config ||= MyUnisoftLib::Api::GetConfiguration.new
      end

      def self.config=(new_config)
        config.member_group_id       = new_config['member_group_id']      if new_config['member_group_id']
        config.granted_for           = new_config['granted_for']          if new_config['granted_for']
        config.target                = new_config['target']               if new_config['target']
        config.x_third_party_secret  = new_config['x_third_party_secret'] if new_config['x_third_party_secret']
        config.base_user_url         = new_config['base_user_url']        if new_config['base_user_url']
        config.base_api_url          = new_config['base_api_url']         if new_config['base_api_url']
        config.user_token            = new_config['user_token']           if new_config['user_token']
      end
    end
  end
end