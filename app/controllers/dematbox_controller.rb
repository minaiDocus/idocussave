# frozen_string_literal: true

class DematboxController < ApplicationController
  if %w[staging sandbox production].include?(Rails.env)
    before_action :authenticate
  end
  # skip_before_action :verify_authenticity_token

  include WashOut::SOAP

  soap_action 'SendFile',
              args: {
                'boxId' => :string,
                'serviceId' => :string,
                'virtualBoxId' => :string,
                'docId' => :string,
                'rawScan' => :string,
                'rawFileExtension' => :string,
                'improvedScan' => :string,
                'improvedFileExtension' => :string,
                'text' => :string
              },
              return: { 'errorReturn' => :string }

  def SendFile
    dematbox_document = Dematbox::CreateDocument.new(params)
    dematbox_document.execute
    @response = CreateDematboxDocumentPresenter.new(dematbox_document).response

    render template: 'dematbox/send_file_response',
           formats: [:xml],
           layout: false,
           content_type: 'text/xml'
  end

  soap_action 'PingOperator',
              return: { 'errorReturn' => :string }

  def PingOperator
    @response = '200:OK'
    render template: 'dematbox/ping_operator_response',
           formats: [:xml],
           layout: false,
           content_type: 'text/xml'
  end

  private

  def authenticate
    unless current_user&.is_admin
      authenticate_or_request_with_http_basic do |name, password|
        name == DematboxConfig::USERNAME && password == DematboxConfig::PASSWORD
      end
    end
  end
end
