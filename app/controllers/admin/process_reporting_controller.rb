# -*- encoding : UTF-8 -*-
class Admin::ProcessReportingController < Admin::AdminController
  #GET /admin/process_reporting
  def index
    year  = params[:year].present?  ? params[:year].to_i  : Time.now.year
    month = params[:month].present? ? params[:month].to_i : Time.now.month

    @time = Time.local(year, month)

    @organizations = Organization.order(created_at: :asc, name: :asc)
  end
end
