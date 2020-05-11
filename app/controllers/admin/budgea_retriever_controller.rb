# frozen_string_literal: true

class Admin::BudgeaRetrieverController < Admin::AdminController
  def index
    export_connector_list
  end

  def export_xls
    filename = "suivi_budgea_retriever.xls"
    data     = BudgeaRetrieverAdminToXlsService.new().execute(true)
    send_data data, type: 'application/vnd.ms-excel', filename: filename
  end

  def export_connector_list
    body = BudgeaRetrieverAdminToXlsService.new().execute

    @body_normal = body[:normal]
    @body_failed = body[:failed]
    @body_bug    = body[:bug]
  end
end