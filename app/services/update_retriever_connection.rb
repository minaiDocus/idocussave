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
    result = if client.response.code == 200
      if data['last_update'].nil? || @retriever.sync_at != Time.parse(data['last_update'])
        @retriever.wait_data
      else
        @retriever.ready
      end
    elsif client.response.code == 202
      @retriever.update(additionnal_fields: data['fields']) if data['fields'].present?
      @retriever.wait_additionnal_info
    else
      @retriever.error
      @retriever.update(error_message: client.error_message)
      false
    end
    @retriever.update(password: nil, dyn_attr: nil, dyn_attr_name: nil, additionnal_fields: nil, answers: nil)
    result
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
      params[:login] = @retriever.login
      params[:password] = @retriever.password if @retriever.password.present?
      params[@retriever.dyn_attr_name] = @retriever.dyn_attr if @retriever.dyn_attr.present?
    end
    params
  end
end
