# -*- encoding : UTF-8 -*-
class RetrieversController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def callback
    authorization = request.headers['Authorization']
    if authorization.present?
      access_token = authorization.split[1]
      # NOTE access_token need to be crypted before searching
      account = BudgeaAccount.where(access_token: access_token).first
      if account
        retrieved_data = RetrievedData.new
        retrieved_data.user = account.user
        retrieved_data.content = params.except(:controller, :action)
        retrieved_data.save
        render text: '', status: :ok
      else
        render text: '', status: :unauthorized
      end
    else
      render text: '', status: :unauthorized
    end
  end
end
