# -*- encoding : UTF-8 -*-
class SyncRetrieverConnection
  class << self
    def execute(retriever)
      new(retriever).sync
    end
  end

  def initialize(retriever)
    @retriever = retriever
  end

  def sync
    result = client.sync_connection(@retriever.api_id)
    if client.response.code == 200 && client.error_message.nil?
      @retriever.ready
    elsif client.response.code == 202
      @retriever.udpate(additionnal_fields: data['fields']) if data['fields'].present?
      @retriever.waiting_additionnal_info
    else
      @retriever.update(error_message: client.error_message)
      @retriever.error
    end
    result
  end

private

  def client
    @client ||= Budgea::Client.new(@retriever.user.budgea_account.access_token)
  end
end
