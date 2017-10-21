# -*- encoding : UTF-8 -*-
class SyncBudgeaConnection
  class << self
    def execute(retriever)
      new(retriever).execute
    end
  end

  def initialize(retriever)
    @retriever = retriever
    @user = @retriever.user
  end

  def execute
    if @retriever.connector.is_budgea_active?
      if @retriever.destroying?
        DestroyBudgeaConnection.execute(@retriever)
      else
        data = if @retriever.budgea_id.nil?
          client.create_connection(connection_params)
        elsif @retriever.configuring?
          client.update_connection(@retriever.budgea_id, connection_params)
        else
          client.trigger_connection(@retriever.budgea_id)
        end

        if client.response.code.in?([200, 202]) && client.error_message.nil?
          if @retriever.budgea_id.nil?
            @retriever.budgea_id = data['id']
            @retriever.sync_at   = Time.parse data['last_update'] if data['last_update'].present?
            @retriever.save
          end

          if client.response.code == 200
            @retriever.success_budgea_connection
          elsif client.response.code == 202
            @retriever.update(budgea_additionnal_fields: data['fields']) if data['fields'].present?
            @retriever.pause_budgea_connection
          end
        else
          @retriever.budgea_error_message = client.error_message
          @retriever.fail_budgea_connection
          false
        end
      end
    end
  end

private

  def client
    @client ||= Budgea::Client.new @user.budgea_account.access_token
  end

  def connection_params
    if @params
      @params
    else
      @params = {}
      if @retriever.budgea_id.nil?
        if @retriever.bank?
          @params[:id_bank] = @retriever.connector.budgea_id
        else
          @params[:id_provider] = @retriever.connector.budgea_id
        end
      end

      if @retriever.additionnal_fields.present?
        @params.merge!(@retriever.answers)
      else
        5.times do |i|
          param = @retriever.send("param#{i+1}")
          @params[param['name']] = param['value'] if param
        end
      end
      @params
    end
  end
end
