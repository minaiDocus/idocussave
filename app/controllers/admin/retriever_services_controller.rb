# frozen_string_literal: true

class Admin::RetrieverServicesController < Admin::AdminController
  def index
    @providers = Connector.budgea.providers.order(name: :asc)
    @banks     = Connector.budgea.banks.order(name: :asc)
  end

  def update_list
    UpdateConnectorsList.delay.execute
    flash[:notice] = 'Mise à jour en cours, veuillez rafraîchir la page dans quelques secondes.'
    redirect_to admin_retriever_services_path
  end
end
