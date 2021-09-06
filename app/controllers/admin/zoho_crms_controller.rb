# frozen_string_literal: true

class Admin::ZohoCrmsController < Admin::AdminController

  def index
    @organizations = Organization.select([:name, :code])
  end

  def synchronize
    if params[:zoho_crm][:all].present?
      flash[:success] = 'Zoho crm API control est en cours de synchronisation toutes les organisations ... Veuillez patienter'
      System::ZohoCrmSynchronizerWorker.perform_async
    else
      organization_codes = params[:zoho_crm][:organization_codes]

      flash[:success] = "Zoho crm API control est en cours de synchronisation pour les organisations suivantes: #{organization_codes.join(', ')}"

      organization_codes.each do |code|
        System::ZohoControl.delay(queue: :high).send_one_organization(code)
      end
    end

    redirect_to admin_zoho_crms_path
  end
end
