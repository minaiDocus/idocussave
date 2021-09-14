# frozen_string_literal: true

class Admin::ZohoCrmsController < Admin::AdminController

  def index
    @organizations = Organization.all.order(name: :asc).map{ |org| ["#{org.name} (#{org.code})", org.code] }
  end

  def synchronize
    if params[:zoho_crm][:all].present?
      System::ZohoCrmSynchronizerWorker.perform_async
      flash[:success] = 'Zoho crm API est en cours de synchronisation ... Vos organisations seront synchronisées dans quelques minutes.'
    else
      organization_codes = params[:zoho_crm][:organization_codes]
      System::ZohoControl.delay(queue: :high).send_arr_organizations(organization_codes)

      flash[:success] = "Les organisations suivantes: #{organization_codes.join(', ')}, sont en cours de synchronisation ... Disponible dans votre crm dans quelques minutes."
    end

    redirect_to admin_zoho_crms_path
  end
end
