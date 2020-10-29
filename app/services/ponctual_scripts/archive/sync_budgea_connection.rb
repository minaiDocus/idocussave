# -*- encoding : UTF-8 -*-
class PonctualScripts::Archive::SyncBudgeaConnection
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
    if @retriever.budgea_connector_id.present?
      if @retriever.destroying?
        Retriever::DestroyBudgeaConnection.execute(@retriever)
      else
        data = if @retriever.budgea_id.nil?
          client.create_connection(connection_params)
        elsif @retriever.configuring?
          client.update_connection(@retriever.budgea_id, connection_params)
        else
          client.trigger_connection(@retriever.budgea_id)
        end

        if client.response.status.in?([200, 202]) && client.error_message.nil?
          if @retriever.budgea_id.nil?
            @retriever.budgea_id = data['id']
            @retriever.sync_at   = Time.parse data['last_update'] if data['last_update'].present?
            @retriever.save
          end

          if client.response.status == 200
            @retriever.success_budgea_connection
            
            if @retriever.user.organization.code == 'AFH'
              RetrieversHistoric.find_or_initialize({
                                                      user_id:      @retriever.user_id,
                                                      connector_id: @retriever.connector_id,
                                                      retriever_id: @retriever.id,
                                                      name:         @retriever.name,
                                                      service_name: @retriever.service_name,
                                                      capabilities: @retriever.capabilities
                                                    })
              Billing::UpdatePeriod.new(@retriever.user.subscription.current_period).execute
            end
          elsif client.response.status == 202
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
    @client ||= Budgea::Client.new @user.budgea_account.try(:access_token)
  end

  def connection_params
    if @params
      @params
    else
      @params = {}
      if @retriever.budgea_id.nil?
        if @retriever.bank?
          @params[:id_bank] = @retriever.budgea_connector_id
        else
          @params[:id_provider] = @retriever.budgea_connector_id
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
