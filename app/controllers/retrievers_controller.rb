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
        retrieved_data.content = params.except(:controller, :action)
        retrieved_data.save
        render text: '', status: :ok
      else
        logger.info [params['user']['id'], access_token].join(' - ')
        render text: '', status: :unauthorized
      end
    else
      render text: '', status: :unauthorized
    end
  end

private

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_debug_retriever_callback.log")
  end
end
