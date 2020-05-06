# frozen_string_literal: true

class Account::InvoicesController < Account::OrganizationController
  def show
    @invoices = @organization.invoices.order(created_at: :desc).page(params[:page])
    @invoice_settings = @organization.invoice_settings.order(created_at: :desc)
    @invoice_setting = InvoiceSetting.new

    @synchronize_date = Date.today
    @synchronize_months = []
    (0..24).each do |month|
      @synchronize_months << [@synchronize_date.prev_month(month).strftime("%b %Y"), @synchronize_date.prev_month(month)]
    end
  end

  def download
    invoice    = Invoice.find params[:id] if params[:id].present?
    authorized = @user.leader?

    if invoice && invoice.organization == @organization && File.exist?(invoice.cloud_content_object.path) && authorized
      filename = File.basename invoice.cloud_content_object.path
      # type = invoice.content_content_type || 'application/pdf'
      # find a way to get active storage mime type
      type = 'application/pdf'
      send_file(invoice.cloud_content_object.path, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  def insert
    @invoice_setting = (params[:invoice_setting][:id].present?) ? InvoiceSetting.find(params[:invoice_setting][:id]) : InvoiceSetting.new()
    @invoice_setting.update(invoice_setting_params)
    @invoice_setting.organization = @organization
    @invoice_setting.user         = User.find_by_code params[:invoice_setting][:user_code]

    if @invoice_setting.save
      flash[:success] = (params[:invoice_setting][:id].present?) ? 'Modifié avec succès' : 'Ajout avec succès.'
    else
      flash[:error] = 'Enregistrement non valide, veuillez verifier les informations.'
    end

    redirect_to account_organization_invoices_path(@organization)
  end

  def synchronize
    if params[:invoice_setting_id].present?
      invoice_setting = InvoiceSetting.find(params[:invoice_setting_id])

      if params[:invoice_setting_synchronize_contains][:period].present?
        period = (params[:invoice_setting_synchronize_contains][:period]).to_date

        flash[:success] = 'Synchronisation des factures en cours ...'

        InvoiceSetting.delay(queue: :high).invoice_synchronize(period, invoice_setting.id)
      end
    else
      flash[:error] = 'Synchronisation échouée, veuillez verifier les informations.'
    end

    redirect_to account_organization_invoices_path(@organization)
  end


  def remove
    InvoiceSetting.find(params[:id]).destroy

    flash[:success] = 'Suppression avec succès.'

    redirect_to account_organization_invoices_path(@organization)
  end

  private

  def invoice_setting_params
    params.require(:invoice_setting).permit(:user_code, :journal_code)
  end
end
