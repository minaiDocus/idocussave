# -*- encoding : UTF-8 -*-
class UpdateRetrieverConnection
  class << self
    def execute(retriever)
      new(retriever).update
    end
  end

  def initialize(retriever)
    @retriever = retriever
  end

  def update
    data = client.update_connection(@retriever.api_id, connection_params)
    if client.response.code == 200
      @retriever.ready
    elsif client.response.code == 202
      @retriever.update(additionnal_fields: data['fields']) if data['fields'].present?
      @retriever.wait_additionnal_info
    else
      @retriever.error
      @retriever.update(error_message: client.error_message)
      false
    end
  end

private

  def client
    @client ||= Budgea::Client.new(@retriever.user.budgea_account.access_token)
  end

  def connection_params
    params = {}
    if @retriever.additionnal_fields.present?
      params.merge!(@retriever.answers)
    else
      4.times do |i|
        param = @retriever.send("param#{i+1}")
        params[param['name']] = param['value'] if param
      end
    end
    params
  end
end
