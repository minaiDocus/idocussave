# -*- encoding : UTf-8 -*-
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
          if retriever.bank?
            retriever.is_documents_locked = false
            retriever.journal = nil
          end
          retriever.save
          FiduceoDocumentFetcher.initiate_transactions retriever
        end
      end
      retriever
    end

    def update(retriever, params)
      retriever.assign_attributes(params)
      if retriever.valid?
        client = Fiduceo::Client.new retriever.user.fiduceo_id
        client.retriever(nil, :put, format_params(retriever))
        if client.response.code == 200
          retriever.save
          FiduceoDocumentFetcher.initiate_transactions retriever
        end
      end
      retriever
    end

    def destroy(retriever)
      client = Fiduceo::Client.new(retriever.user.fiduceo_id)
      if retriever.bank?
        results = client.bank_accounts
        if client.response.code == 200
          results.each do |bank_account|
            if bank_account.retriever_id == retriever.fiduceo_id
              client.bank_account(bank_account.id, :delete)
            end
          end
        end
      end
      client.retriever(retriever.fiduceo_id, :delete)
      retriever.destroy
    end

    def format_params(retriever)
      params = {}
      if retriever.fiduceo_id
        params.merge!({ id: retriever.fiduceo_id })
      else
        if retriever.type == 'provider'
          params.merge!({ provider_id: retriever.provider_id })
        else
          params.merge!({ provider_id: retriever.bank_id })
        end
      end
      params.merge!({ label: retriever.name, login: retriever.login }) if retriever.login_changed?
      params.merge!({ pass: retriever.pass }) if retriever.pass.present?
      params.merge!({ param1: retriever.param1 }) if retriever.param1.present?
      params.merge!({ param2: retriever.param2 }) if retriever.param2.present?
      params.merge!({ param3: retriever.param3 }) if retriever.param3.present?
      params.merge!({ active: retriever.is_active.to_s }) if retriever.is_active_changed?
      params
    end
  end
end
