# -*- encoding : UTF-8 -*-
class Admin::MobileReportingController < Admin::AdminController
  def index
    @users = User.active.all.distinct.count

    @mobile_users = MobileConnexion.periode(date_params).group(:user_id).count.size
    @ios_users = MobileConnexion.ios.periode(date_params).group(:user_id).count.size
    @android_users = MobileConnexion.android.periode(date_params).group(:user_id).count.size

    temp_documents = TempDocument.where("state='processed' AND delivery_type = 'upload' AND DATE_FORMAT(created_at, '%Y%m') = #{date_params}")
    @documents = temp_documents.size
    @mobile_documents = temp_documents.select{|d| d.api_name == 'mobile'}.size
  end

  def download_mobile_users
    filename = "Reporting_users_application_iDocus_#{date_params}.xls"
    send_data MobileReportingXls.new(date_params).users_report, type: 'application/vnd.ms-excel', filename: filename
  end

  def download_mobile_documents
    filename = "Reporting_documents_application_iDocus_#{date_params}.xls"
    send_data MobileReportingXls.new(date_params).documents_report, type: 'application/vnd.ms-excel', filename: filename
  end

  private

  def date_params
    return "#{@year_params}#{@month_params}" if @year_params.present? && @month_params.present?

    @year_params = params[:year].present? ? params[:year].to_s : Date.today.strftime("%Y").to_s
    @month_params = params[:month].present? ? params[:month].to_s : Date.today.strftime("%m").to_s

    "#{@year_params}#{@month_params}"
  end
end
