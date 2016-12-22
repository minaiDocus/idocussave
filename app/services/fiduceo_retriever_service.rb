# -*- encoding : UTf-8 -*-
### Fiduceo related - remained untouched (or nearly) : to be deprecated soon ###
class FiduceoRetrieverService
  class << self
    def create(user, params)
      retriever = FiduceoRetriever.new params
      retriever.user = user
      if retriever.valid?
        client = Fiduceo::Client.new user.fiduceo_id
        result = client.retriever(nil, :put, format_params(retriever))
        if client.response.code == 200
          retriever.fiduceo_id = result['id']
          list = FiduceoProvider.new user.fiduceo_id
          if retriever.bank?
            retriever.journal = nil
            bank = list.banks.select { |e| e[:id] == params[:bank_id] }.first
            retriever.wait_for_user = bank[:wait_for_user]
            retriever.wait_for_user_label = bank[:wait_for_user_label]
            input = bank[:inputs].select { |input| input[:name].match /\Acaisse\z/i }.first
            retriever.cash_register = retriever.send(input[:tag]) if input
          elsif retriever.provider?
            provider = list.providers.select { |e| e[:id] == params[:provider_id] }.first
            retriever.wait_for_user = provider[:wait_for_user]
            retriever.wait_for_user_label = provider[:wait_for_user_label]
          end
          retriever.frequency = 'mon-fri' if retriever.service_name =~ /bnp/i
          retriever.journal_name = retriever.journal.try(:name)
          retriever.save
          FiduceoDocumentFetcher.initiate_transactions retriever
        end
      end
      retriever
    end

    def update(retriever, params)
      retriever.assign_attributes(params)
      if retriever.valid?
        is_name_changed = retriever.name_changed?
        client = Fiduceo::Client.new retriever.user.fiduceo_id
        client.retriever(nil, :put, format_params(retriever))
        if client.response.code == 200
          if retriever.bank?
            retriever.journal = nil
            list = FiduceoProvider.new retriever.user.fiduceo_id
            bank = list.banks.select { |e| e[:id] == retriever.bank_id }.first
            input = bank[:inputs].select { |input| input[:name].match /\Acaisse\z/i }.first
            retriever.cash_register = retriever.send(input[:tag]) if input
          end
          retriever.journal_name = retriever.journal.try(:name)
          retriever.save
          if retriever.error? && params[:pass].present?
            retriever.schedule
            retriever.update_attribute(:is_password_renewal_notified, false)
          end
          if is_name_changed
            retriever.transactions.update_all(custom_service_name: retriever.name)
            retriever.temp_documents.update_all(fiduceo_custom_service_name: retriever.name)
          end
          FiduceoDocumentFetcher.initiate_transactions retriever
        end
      end
      retriever
    end

    def destroy(retriever)
      retriever.transactions.not_processed.destroy_all
      client = Fiduceo::Client.new(retriever.user.fiduceo_id)
      client.retriever(retriever.fiduceo_id, :delete)
      retriever.destroy if client.response.code.in?([200, 204])
    end

    def format_params(retriever)
      params = {}
      if retriever.fiduceo_id
        params[:id] = retriever.fiduceo_id
      else
        params[:provider_id] = if retriever.type == 'provider'
                                 retriever.provider_id
                               else
                                 retriever.bank_id
                               end
      end
      if retriever.login_changed?
        params[:label] = retriever.name
        params[:login] = retriever.login
      end
      params[:pass] = retriever.pass if retriever.pass.present?
      params[:param1] = retriever.param1 if retriever.param1.present?
      params[:param2] = retriever.param2 if retriever.param2.present?
      params[:param3] = retriever.param3 if retriever.param3.present?
      params[:active] = retriever.is_active.to_s if retriever.is_active_changed?
      params
    end
  end
end
