# -*- encoding : UTF-8 -*-
class DropboxesController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def webhook
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), Dropbox::APP_SECRET, request.body.read)
    if signature == request.headers['X-Dropbox-Signature']
      DropboxBasic.where(:dropbox_id.in => params[:delta][:users]).update_all(changed_at: Time.now)
      render text: 'OK'
    else
      render text: 'Unauthorized.'
    end
  end
end
