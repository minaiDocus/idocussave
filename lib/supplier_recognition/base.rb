module SupplierRecognition
  class Base
    CONFIG = YAML.load_file('config/supplier_recognition.yml').freeze

    def self.connection
      ApiBroker::Request.new(CONFIG['supplier_recognition']['base_url'], 
                             CONFIG['supplier_recognition']['api_content_type'], 
                             CONFIG['supplier_recognition']['authentication_header'], 
                             CONFIG['supplier_recognition']['api_token'])
    end
  end
end