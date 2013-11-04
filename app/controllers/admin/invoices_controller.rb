# -*- encoding : UTF-8 -*-
class Admin::InvoicesController < Admin::AdminController
  before_filter :load_invoice, except: :index

  def index
    @invoices = search(invoice_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def show
    file_path = @invoice.content.path params[:style]
    if File.exist?(file_path)
      filename = File.basename file_path
      type = @invoice.content_content_type || 'application/pdf'
      send_file(file_path, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  def update
    @invoice.update_attributes(params[:invoice])
    respond_to do |format|
      format.html { redirect_to admin_invoices_path }
      format.json { render json: {}, status: :ok }
    end
  end

private

  def load_invoice
    @invoice = Invoice.find_by_number params[:id]
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def invoice_contains
    @contains ||= {}
    if params[:invoice_contains] && @contains.blank?
      @contains = params[:invoice_contains].delete_if do |key,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :invoice_contains

  def search(contains)
    invoices = Invoice.all
    if contains[:amount_in_cents_w_vat].present?
      comparison_operator = contains[:amount_in_cents_w_vat_comparison_operator]
      invoices = invoices.where("amount_in_cents_w_vat.#{comparison_operator}" => contains[:amount_in_cents_w_vat])
    end
    if params[:user_contains] && params[:user_contains][:code]
      users = User.where(code: /#{params[:user_contains][:code]}/)
      if users.count == 1
        user = users.first
        if user.my_organization
          invoices = invoices.where(organization_id: user.my_organization.id)
        else
          invoices = invoices.where(user_id: user.id)
        end
      elsif users.count > 1
        leaders = users.select { |e| e.my_organization.present? }
        organization_ids = leaders.map { |e| e.my_organization.id }
        customers = users.select { |e| e.my_organization.nil? }
        invoices = invoices.any_of({ :user_id.in => customers.map(&:_id) }, { :organization_id.in => organization_ids })
      end
    end
    invoices = invoices.where(number: /#{contains[:number]}/i) unless contains[:number].blank?
    invoices = invoices.where(number: /#{contains[:number]}/i) unless contains[:number].blank?
    invoices = invoices.where(created_at: contains[:created_at]) unless contains[:created_at].blank?
    invoices = invoices.where(requested_at: contains[:requested_at]) unless contains[:requested_at].blank?
    invoices = invoices.where(received_at: contains[:received_at]) unless contains[:received_at].blank?
    invoices
  end
end