# frozen_string_literal: true

module Account::RetrieverHelper
  def retriever_dyn_attrs(retriever)
    hsh = {}
    5.times do |i|
      param_name = "param#{i + 1}"
      data = retriever.send(param_name)
      next unless data

      data = data.dup # data is frozen due to encryption so we use a duplicate
      data['error'] = retriever.errors[param_name].first
      data['value'] = nil if data['type'] == 'password'
      hsh[param_name] = data
    end
    hsh.to_json
  end

  def retriever_states
    {
      '-': '',
      'OK': 'ready',
      'Synchronisation en cours': 'configuring',
      'Suppression en cours': 'destroying',
      'Sélection de documents': 'waiting_selection',
      "En attente de l'utilisateur": 'waiting_additionnal_info',
      'Erreur': 'error',
      "Indisponible": 'unavailable'
    }
  end

  def customers_active
    if @user.organization.specific_mission
      accounts.map { |u| [u, u.id] } || []
    else
      accounts.active.map { |u| [u, u.id] } || []
    end
  end

  # def link_retriever_options(account)
  #   { class: account.try(:id)? '' : 'disabled', title: account.try(:id)? '' : 'Sélectionnez un dossier pour pouvoir poursuivre' }
  # end
end
