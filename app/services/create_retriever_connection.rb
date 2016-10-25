# -*- encoding : UTF-8 -*-
class CreateRetrieverConnection
  class << self
    def execute(retriever)
      new(retriever).create
    end
  end

  def initialize(retriever)
    @retriever = retriever
    @user = @retriever.user
  end

  def create
    data = client.create_connection(connection_params)
    if client.response.code.in? [200, 202]
      @retriever.api_id             = data['id']
      @retriever.sync_at            = Time.parse data['last_update'] if data['last_update'].present?
      @retriever.additionnal_fields = data['fields'] if data['fields'].present?
      @retriever.save
      if client.response.code == 200
        @retriever.ready
      else
        @retriever.wait_additionnal_info
      end
    else
      @retriever.update(error_message: client.error_message)
      @retriever.error
      false
    end
  end

private

  def client
    @client ||= Budgea::Client.new(@user.budgea_account.access_token)
  end

  def connection_params
    if @retriever.bank?
      params = { id_bank: @retriever.bank_id }
    else
      params = { id_provider: @retriever.provider_id }
    end
    4.times do |i|
      param = @retriever.send("param#{i+1}")
      params[param['name']] = param['value'] if param
    end
    params
  end
end
