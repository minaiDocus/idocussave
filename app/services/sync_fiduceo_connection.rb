# -*- encoding : UTF-8 -*-
class SyncFiduceoConnection
  class << self
    def execute(retriever, fetch_data=true)
      new(retriever, fetch_data).execute
    end
  end

  def initialize(retriever, fetch_data=true)
    @retriever  = retriever
    @user       = @retriever.user
    @fetch_data = fetch_data
  end

  def execute
    if @retriever.connector.is_fiduceo_active?
      if @retriever.destroying?
        client.retriever(@retriever.fiduceo_id, :delete)
        @retriever.destroy_fiduceo_connection if client.response.code.in?([200, 204])
      elsif @retriever.running?
        create_transaction
      else
        data = client.retriever(nil, :put, connection_params)
        if client.response.code == 200
          @retriever.update(fiduceo_id: data['id']) if @retriever.fiduceo_id.nil?
          if @retriever.fiduceo_connection_failed? && connection_params[:pass].present?
            # TODO verify
            @retriever.update(is_new_password_needed: false)
          end
          create_transaction
        else
          @retriever.destroy_budgea_connection = client.response.body
          @retriever.fail_fiduceo_connection
          false
        end
      end
    end
  end

private

  def client
    @client ||= Fiduceo::Client.new @user.fiduceo_id
  end

  def connection_params
    if @params
      @params
    else
      @params = {}
      if @retriever.fiduceo_id
        @params[:id] = @retriever.fiduceo_id
      else
        @params[:provider_id] = @retriever.connector.fiduceo_id
      end
      @params[:label] = @retriever.name
      5.times do |i|
        param = @retriever.send("param#{i+1}")
        if param
          name = @retriever.connector.combined_fields[param['name']]['fiduceo_name']
          # name can be login/pass/param1/param2/param3
          @params[name.to_sym] = param['value'] if name
        end
      end
      @params
    end
  end

  def create_transaction
    data = client.retriever(@retriever.fiduceo_id, :post)
    if client.response.code == 200
      @retriever.update(fiduceo_transaction_id: data['id'])
      UpdateFiduceoRetrieverStatus.execute(@retriever, @fetch_data)
    else
      @retriever.fiduceo_error_message = client.response.body
      @retriever.fail_fiduceo_connection
      false
    end
  end
end
