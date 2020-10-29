# frozen_string_literal: true

class Admin::BudgeaRetrieverController < Admin::AdminController
  def index; end

  def export_xls
    filename = "suivi_budgea_retriever.xls"
    Timeout.timeout 3600 do
      data     = Retriever::BudgeaAdminToXls.new().execute('data')
    end
    send_data data, type: 'application/vnd.ms-excel', filename: filename
  end

  def export_connector_list
    body = Retriever::BudgeaAdminToXls.new().execute('table')

    @body_normal = body[:normal]
    @body_failed = body[:failed]
    @body_bug    = body[:bug]

    render partial: 'admin/budgea_retriever/body'
  end

  def get_all_users
    filename = "Utilisateurs_budgea_retriever.xls"
    Timeout.timeout 300 do
      results  = Retriever::BudgeaAdminToXls.new.for_users
    end
    send_data results, type: 'application/vnd.ms-excel', filename: filename
  end
end