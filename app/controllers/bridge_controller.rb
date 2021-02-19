class BridgeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def setup_item
    user = params[:account_id] ? User.find(params[:account_id]) : current_user

    if user
      Bridge::CreateUser.new(user).execute

      redirect_to Bridge::CreateItem.new(user).execute
    end
  end

  def delete_item
    retriever = Retriever.find(params[:retriever_id])

    Bridge::DeletetItem.new(retriever.user, retriever).execute

    redirect_to account_retrievers_path
  end

  def callback
    unless params[:user_uuid].blank?
      bridge_account = BridgeAccount.find_by(identifier: params[:user_uuid])

      Bridge::GetItems.new(bridge_account.user).execute

      Bridge::GetAccounts.new(bridge_account.user).execute
    end

    redirect_to(account_retrievers_path)
  end
end