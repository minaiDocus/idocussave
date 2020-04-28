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
      zip_path = InvoicesToZip.new(params['invoice_ids']).execute
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

    csv = SepaDirectDebitGenerator.execute(invoice_time, debit_date)

    filename = "order_#{invoice_time.strftime('%Y%m')}.csv"

    send_data(csv, type: 'text/csv', filename: filename)
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
end
