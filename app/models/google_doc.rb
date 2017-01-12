# -*- encoding : UTF-8 -*-
class GoogleDoc < ActiveRecord::Base
  belongs_to :external_file_storage


  def is_configured?
    is_configured
  end


  def reset
    update(token: '', refresh_token: '', token_expires_at: nil, is_configured: false)
  end


  def user
    external_file_storage.user
  end
end
