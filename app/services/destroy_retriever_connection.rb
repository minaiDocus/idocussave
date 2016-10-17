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
    if @retriever.api_id.present? && is_retriever_uniq?
      if client.destroy_connection(@retriever.api_id)
        # TODO take into account a duplication of connection
        @retriever.bank_accounts.destroy_all
        @retriever.destroy
      else
        @retriever.update(error_message: client.error_message)
        @retriever.error
        false
      end
    else
      @retriever.bank_accounts.destroy_all
      @retriever.destroy
    end
  end

private

  def client
    @client ||= Budgea::Client.new @user.budgea_account.access_token
  end

  def is_retriever_uniq?
    @user.retrievers.where(api_id: @retriever.api_id).count == 1
  end
end
