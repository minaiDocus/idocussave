# frozen_string_literal: true

class Admin::BudgeaRetrieverController < Admin::AdminController
  def index; end

  def export_xls
    filename = "suivi_budgea_retriever.xls"
    data     = BudgeaRetrieverAdminToXlsService.new().execute('data')
    send_data data, type: 'application/vnd.ms-excel', filename: filename
  end

  def export_connector_list
    body = BudgeaRetrieverAdminToXlsService.new().execute('table')

    @body_normal = body[:normal]
    @body_failed = body[:failed]
    @body_bug    = body[:bug]

    render partial: 'admin/budgea_retriever/body'
  end

  def get_all_users
    filename = "Utilisateurs_budgea_retriever.xls"
    results  = BudgeaRetrieverAdminToXlsService.new.for_users

    send_data results, type: 'application/vnd.ms-excel', filename: filename
  end
end