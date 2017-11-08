# -*- encoding : UTF-8 -*-
class RetrieversController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def callback
    authorization = request.headers['Authorization']
    if authorization.present? && params['user']
      access_token = authorization.split[1]
      account = BudgeaAccount.where(identifier: params['user']['id']).first
      if account && account.access_token == access_token
        retrieved_data = RetrievedData.new
        retrieved_data.user = account.user
        retrieved_data.json_content = params.except(:controller, :action)
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
