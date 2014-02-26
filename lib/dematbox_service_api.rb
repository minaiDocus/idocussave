# -*- encoding : UTF-8 -*-
class DematboxServiceApi
  class Configuration
    attr_accessor :is_active, :wsdl, :provisioning_wsdl, :namespace, :namespace_identifier, :env_namespace, :soap_version, :pretty_print_xml, :log, :logger, :log_level, :ssl_verify_mode, :ssl_version, :ssl_cert_file, :ssl_cert_key_file, :ssl_ca_cert_file, :virtual_box_id, :box_id, :service_id, :associated_service_id

    def initialize
      @is_active            = true
      @namespace_identifier = :ser
      @env_namespace        = :soapenv
      @soap_version         = 1
      @pretty_print_xml     = Rails.env.production? ? false : true
      @log                  = Rails.env.production? ? false : true
      @logger               = Rails.env.production? ? Rails.logger : Logger.new(STDOUT)
      @log_level            = Rails.env.production? ? :info : :debug
      @virtual_box_id       = "0"
      @ssl_verify_mode      = :none
    end
  end

  class << self
    attr_accessor :config, :client, :request, :response

    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    def config=(new_config)
      config.is_active             = new_config['is_active']              unless new_config['is_active'].nil?
      config.wsdl                  = new_config['wsdl']                   if new_config['wsdl']
      config.provisioning_wsdl     = new_config['provisioning_wsdl']      if new_config['provisioning_wsdl']
      config.namespace             = new_config['namespace']              if new_config['namespace']
      config.namespace_identifier  = new_config['namespace_identifier']   if new_config['namespace_identifier']
      config.env_namespace         = new_config['env_namespace']          if new_config['env_namespace']
      config.soap_version          = new_config['soap_version']           if new_config['soap_version']
      config.pretty_print_xml      = new_config['pretty_print_xml']       if new_config['pretty_print_xml']
      config.log                   = new_config['log']                    if new_config['log']
      config.logger                = new_config['logger']                 if new_config['logger']
      config.log_level             = new_config['log_level'].to_sym       if new_config['log_level']
      config.ssl_verify_mode       = new_config['ssl_verify_mode'].to_sym if new_config['ssl_verify_mode']
      config.ssl_version           = new_config['ssl_version'].to_sym     if new_config['ssl_version']
      config.ssl_cert_file         = new_config['ssl_cert_file']          if new_config['ssl_cert_file']
      config.ssl_cert_key_file     = new_config['ssl_cert_key_file']      if new_config['ssl_cert_key_file']
      config.ssl_ca_cert_file      = new_config['ssl_ca_cert_file']       if new_config['ssl_ca_cert_file']
      config.virtual_box_id        = new_config['virtual_box_id']         if new_config['virtual_box_id']
      config.box_id                = new_config['box_id']                 if new_config['box_id']
      config.service_id            = new_config['service_id']             if new_config['service_id']
      config.associated_service_id = new_config['associated_service_id']  if new_config['associated_service_id']
    end

    def client
      @client ||= Savon::Client.new do
        wsdl                 DematboxServiceApi.config.wsdl
        namespace            DematboxServiceApi.config.namespace
        namespace_identifier DematboxServiceApi.config.namespace_identifier
        env_namespace        DematboxServiceApi.config.env_namespace
        soap_version         DematboxServiceApi.config.soap_version
        pretty_print_xml     DematboxServiceApi.config.pretty_print_xml
        log                  DematboxServiceApi.config.log
        logger               DematboxServiceApi.config.logger
        log_level            DematboxServiceApi.config.log_level

        if DematboxServiceApi.config.ssl_verify_mode != :none
          ssl_verify_mode   DematboxServiceApi.config.ssl_verify_mode
          ssl_version       DematboxServiceApi.config.ssl_version
          ssl_cert_file     DematboxServiceApi.config.ssl_cert_file
          ssl_cert_key_file DematboxServiceApi.config.ssl_cert_key_file
          ssl_ca_cert_file  DematboxServiceApi.config.ssl_ca_cert_file
        end
      end
    end

    def send_file(file_path)
      response = nil
      File.open(file_path, 'r') do |file|
        response = client.call :send_file, message: {
          'ser:boxId'            => DematboxServiceApi.config.box_id,
          'ser:serviceId'        => DematboxServiceApi.config.associated_service_id,
          'ser:rawScan'          => Base64.encode64(file.readlines.join),
          'ser:rawFileExtension' => 'pdf'
        }
      end
      response.body[:send_file_response][:send_file_return][:doc_id]
    end

    def upload_notification(doc_id, box_id)
      message = {
        'ser:docId' => doc_id,
        'ser:boxId' => box_id
      }
      response = client.call :upload_notification, message: message
      response.body[:upload_notification_response][:error_return]
    end

    def list(box_id)
      _client ||= Savon::Client.new do
        wsdl                 DematboxServiceApi.config.provisioning_wsdl
        namespace            DematboxServiceApi.config.namespace
        namespace_identifier DematboxServiceApi.config.namespace_identifier
        env_namespace        DematboxServiceApi.config.env_namespace
        soap_version         DematboxServiceApi.config.soap_version
        pretty_print_xml     DematboxServiceApi.config.pretty_print_xml
        log                  DematboxServiceApi.config.log
        logger               DematboxServiceApi.config.logger
        log_level            DematboxServiceApi.config.log_level

        if DematboxServiceApi.config.ssl_verify_mode != :none
          ssl_verify_mode   DematboxServiceApi.config.ssl_verify_mode
          ssl_version       DematboxServiceApi.config.ssl_version
          ssl_cert_file     DematboxServiceApi.config.ssl_cert_file
          ssl_cert_key_file DematboxServiceApi.config.ssl_cert_key_file
          ssl_ca_cert_file  DematboxServiceApi.config.ssl_ca_cert_file
        end
      end
      _client.call :services_list_v2, message: { 'ser:boxId' => box_id }
    end
  end
end
