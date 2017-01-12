# -*- encoding : UTF-8 -*-
class DropboxesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /dropbox/webhook
  def webhook
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), Dropbox::APP_SECRET, request.body.read)

    if signature == request.headers['X-Dropbox-Signature']
      DropboxBasic.where(dropbox_id: params[:delta][:users]).update_all(changed_at: Time.now)
      render status: :ok, text: 'OK'
    else
      render status: :unauthorized, text: 'Unauthorized.'
    end
  end


  def verify
    render text: params[:challenge] and return if params[:challenge].present?
    render text: 'challenge parameter is missing' 
  end
end
