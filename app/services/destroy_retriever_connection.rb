# -*- encoding : UTF-8 -*-
class DestroyRetrieverConnection
  class << self
    def execute(retriever)
      new(retriever).destroy
    end
  end

  def initialize(retriever)
    @retriever = retriever
    @user = @retriever.user
  end

  def destroy
    is_destroyed = false
    @user.budgea_account.with_lock(timeout: 2, retries: 10, retry_sleep: 0.2) do
      if @retriever.api_id.nil? || is_retriever_not_uniq?
        @retriever.bank_accounts.destroy_all
        is_destroyed = @retriever.destroy
      end
    end
    return true if is_destroyed

    if client.destroy_connection(@retriever.api_id)
      @retriever.bank_accounts.destroy_all
      @retriever.destroy
    else
      @retriever.update(error_message: client.error_message)
      @retriever.error
      false
    end
  end

private

  def client
    @client ||= Budgea::Client.new @user.budgea_account.access_token
  end

  def is_retriever_not_uniq?
    @user.retrievers.where(api_id: @retriever.api_id).count > 1
  end
end
