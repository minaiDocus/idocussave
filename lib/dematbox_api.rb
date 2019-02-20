# -*- encoding : UTF-8 -*-
class DematboxApi
  def self.client
    @client ||= Savon::Client.new do
      wsdl DematboxConfig::WSDL
      namespace DematboxConfig::NAMESPACE
      namespace_identifier :ser
      env_namespace :soapenv
      soap_version 1
      pretty_print_xml true
      log true
      logger DematboxConfig::LOGGER
      log_level DematboxConfig::LOG_LEVEL.to_sym

      ssl_verify_mode DematboxConfig::SSL_VERIFY_MODE
      ssl_version DematboxConfig::SSL_VERSION
      ssl_cert_file DematboxConfig::SSL_CERT_FILE
      ssl_cert_key_file DematboxConfig::SSL_CERT_KEY_FILE
      ssl_ca_cert_file DematboxConfig::SSL_CA_CERT_FILE
    end
  end


  def self.services
    Rails.cache.fetch([:dematbox, :services], expires_in: 5.minutes) do
      begin
        response = client.call :get_service_list, message: { 'ser:operatorId' => DematboxConfig::OPERATOR_ID }, soap_action: ''
        response.body[:get_service_list_response][:service_list][:service]
      rescue => e
        "[#{e.class}] #{e.message}"
      end
    end
  end


  # Register a dematbox with idocus
  def self.subscribe(code, services, pairing_code = nil)
    message = {
      'ser:operatorId' => DematboxConfig::OPERATOR_ID,
      'ser:virtualBoxId' => code,
      'ser:services' => { service: services }
    }

    message['ser:pairingCode'] = pairing_code if pairing_code.present?

    response = client.call :put_service_subscribe, message: message, soap_action: ''

    response.body[:put_service_subscribe_response][:error_return]
  rescue => e
    "[#{e.class}] #{e.message}"
  end


  # Remove dematbox registration with idocus
  def self.unsubscribe(code)
    message = {
      'ser:operatorId' => DematboxConfig::OPERATOR_ID,
      'ser:virtualBoxId' => code
    }

    response = client.call :service_unsubscribe, message: message, soap_action: ''

    response.body[:service_unsubscribe_response][:error_return]
  rescue => e
    "[#{e.class}] #{e.message}"
  end


  # Unused but not deleted, just in case ...
  def self.subscribed(code)
    message = {
      'ser:operatorId' => DematboxConfig::OPERATOR_ID,
      'ser:virtualBoxId' => code
    }

    response = client.call :get_service_subscribed, message: message, soap_action: ''

    response.body[:get_service_subscribed_response][:services][:service]
  rescue => e
    "[#{e.class}] #{e.message}"
  end


  # Notifies sagemcom that we successfully got the dcoument, unlocks the physical dematbox
  def self.notify_uploaded(doc_id, box_id, message = nil)
    message = {
      'ser:operatorId' => DematboxConfig::OPERATOR_ID,
      'ser:boxId' => box_id,
      'ser:docId' => doc_id,
      'ser:message' => message,
      'ser:messageDuration' => 5
    }

    response = client.call :upload_notification, message: message, soap_action: ''

    response.body[:upload_notification_response][:error_return]
  end
end
