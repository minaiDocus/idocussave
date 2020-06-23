module Jefacture
  class Base
    CONFIG = YAML.load_file('config/jefacture.yml').freeze

    def self.connection
      ApiBroker::Request.new(CONFIG['jefacture']['base_url'], 
                             CONFIG['jefacture']['api_content_type'], 
                             CONFIG['jefacture']['authentication_header'], 
                             CONFIG['jefacture']['api_token'])
    end
  end
end