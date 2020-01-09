# frozen_string_literal: true

class DropboxesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def webhook
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), Rails.application.credentials[Rails.env.to_sym][:dropbox_api][:secret], request.body.read)

    #Tmp Oversight: dropbox webhook
    logger.info "[Webhook - signature] #{signature}"
    logger.info "[Webhook - header] #{request.headers['X-Dropbox-Signature']} - match : #{(signature == request.headers['X-Dropbox-Signature']).to_s}"

    if signature == request.headers['X-Dropbox-Signature']
      DropboxBasic.where(dropbox_id: params[:delta][:users]).update_all(changed_at: Time.now)
      render status: :ok, plain: 'OK'
    else
      render status: :unauthorized, plain: 'Unauthorized.'
    end
  end

  def verify
    render(plain: params[:challenge]) && return if params[:challenge].present?
    render plain: 'challenge parameter is missing'
  end

  private

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_dropbox_webhook.log")
  end
end
