# -*- encoding : UTF-8 -*-
class DestroyBudgeaConnection
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
    lock.synchronize("#{@user.id}_destroy_budgea_connection", expiry: 4.seconds) do
      if @retriever.budgea_id.nil? || is_retriever_not_uniq?
        @retriever.bank_accounts.destroy_all
        is_destroyed = @retriever.destroy_budgea_connection
      end
    end
    return true if is_destroyed

    if client.destroy_connection(@retriever.budgea_id)
      @retriever.bank_accounts.destroy_all
      @retriever.destroy_budgea_connection
    else
      @retriever.update(budgea_error_message: client.error_message)
      @retriever.fail_budgea_connection
      false
    end
  end

private

  def client
    @client ||= Budgea::Client.new @user.budgea_account.access_token
  end

  def is_retriever_not_uniq?
    @user.retrievers.where(budgea_id: @retriever.budgea_id).count > 1
  end

  def lock
    $lock ||= RemoteLock.new(RemoteLock::Adapters::Redis.new(Redis.new))
  end
end
