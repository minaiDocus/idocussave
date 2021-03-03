# frozen_string_literal: true

class Admin::InvoicesController < Admin::AdminController
  before_action :load_invoice, only: %w[show update]

  # GET /admin/invoices
  def index
    @invoices = Invoice.search(search_terms(params[:invoice_contains])).order(sort_column => sort_direction)

    @invoices_count = @invoices.count

    @invoices = @invoices.page(params[:page]).per(params[:per_page])
  end

  # GET /admin/invoices/archive
  def archive
    file_path = ArchiveInvoice.archive_path(params[:file_name])

    if File.exist? file_path
      send_file(file_path, type: 'application/zip', filename: params[:file_name], x_sendfile: true)
    else
      raise ActionController::RoutingError, 'Not Found'
    end
  end

  # GET /admin/invoices/:id/download
  def download
    if params['invoice_ids'].present?
      zip_path = Billing::InvoicesToZip.new(params['invoice_ids']).execute
      send_file(zip_path, type: 'application/zip', filename: 'factures.zip', x_sendfile: true)
    else
      redirect_to admin_invoices_path
    end
  end

  # POST /admin/invoices/debit_order
  def debit_order
    debit_date = begin
                  params[:debit_date].presence.to_date
                 rescue StandardError
                   Date.today
                end

    invoice_time = begin
                    params[:invoice_date].presence.to_time
                   rescue StandardError
                     Time.now
                  end

    @csv = Billing::SepaDirectDebitGenerator.execute(invoice_time, debit_date)

    @filename = "order_#{invoice_time.strftime('%Y%m')}.csv"

    mail_infos = {
      subject: "[Admin::InvoicesController] generate invoice debit order csv file with #{current_user.info}",
      name: "Admin::InvoicesController.debit_order",
      error_group: "[admin-invoices-controller] generate invoice debit order csv file",
      erreur_type: "Generate invoice debit order csv file",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: {
        target_name: request.path,
        path: request.path,
        remote_ip: request.remote_ip,
        user_info: current_user.info,
        debit_date: debit_date,
        invoice_time: invoice_time,
        method: "debit_order"
      }
    }

    begin
      store_invoice_debit_order
      ErrorScriptMailer.error_notification(mail_infos, { attachements: [{name: @filename, file: File.read(file_path)}] } ).deliver
    rescue
      ErrorScriptMailer.error_notification(mail_infos).deliver
    end

    send_data(@csv, type: 'text/csv', filename: @filename)
  end

  # GET /admin/invoices/:id
  def show
    if File.exist?(@invoice.cloud_content_object.path.to_s)
      # type     = @invoice.content_content_type || 'application/pdf'
      # Find a way to get active record mime type
      type = 'application/pdf'
      filename = File.basename @invoice.cloud_content_object.path
      send_file(@invoice.cloud_content_object.path, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    end
  end

  private

  def load_invoice
    @invoice = Invoice.find(params[:id])
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def store_invoice_debit_order
    File.write(file_path, @csv)
  end

  def file_path
    File.join(invoice_dir, @filename)
  end

  def invoice_dir
    dir = "#{Rails.root}/files/invoices"
    FileUtils.makedirs(dir)
    FileUtils.chmod(0777, dir)
    dir
  end
end
