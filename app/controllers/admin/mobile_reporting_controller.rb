# frozen_string_literal: true

class Admin::MobileReportingController < Admin::AdminController
  def index
    date_params

    if params[:ajax]
      if params[:mobile_users_count]
        get_stats_mobile_users
        render json: { users: @users, ios_users: @ios_users, android_users: @android_users, mobile_users: @mobile_users }, status: 200
      elsif params[:users_uploader_count]
        get_stats_mobile_visit
        render json: { mobile_users: @mobile_users, mobile_users_uploader: @mobile_users_uploader }, status: 200
      elsif params[:documents_uploaded]
        get_stats_uploaded_documents
        render json: { documents: @documents, mobile_documents: @mobile_documents }, status: 200
      else
        render json: { error: 'Unauthorized request' }, status: 401
      end
    end
  end

  def download_mobile_users
    filename = "Reporting_users_application_iDocus_#{date_params}.xls"
    send_data Report::MobileToXls.new(date_params).users_report, type: 'application/vnd.ms-excel', filename: filename
  end

  def download_mobile_documents
    filename = "Reporting_documents_application_iDocus_#{date_params}.xls"
    send_data Report::MobileToXls.new(date_params).documents_report, type: 'application/vnd.ms-excel', filename: filename
  end

  private

  def date_params
    if @year_params.present? && @month_params.present?
      return "#{@year_params}#{@month_params}"
    end

    @year_params = params[:year].present? ? params[:year].to_s : Date.today.strftime('%Y').to_s
    @month_params = params[:month].present? ? params[:month].to_s : Date.today.strftime('%m').to_s

    "#{@year_params}#{@month_params}"
  end

  def get_stats_mobile_users
    @users = User.active.all.distinct.count
    @mobile_users = MobileConnexion.periode(date_params).joins(:user).merge(User.active).group(:user_id).count.size
    @ios_users = MobileConnexion.ios.periode(date_params).joins(:user).merge(User.active).group(:user_id).count.size
    @android_users = MobileConnexion.android.periode(date_params).joins(:user).merge(User.active).group(:user_id).count.size
  end

  def get_stats_mobile_visit
    @mobile_users = MobileConnexion.periode(date_params).joins(:user).merge(User.active).group(:user_id).count.size
    @mobile_users_uploader = TempDocument.from_mobile.where("DATE_FORMAT(created_at, '%Y%m') = #{date_params}").distinct.select(:delivered_by).count
  end

  def get_stats_uploaded_documents
    @documents = TempDocument.where("state='processed' AND delivery_type = 'upload' AND DATE_FORMAT(created_at, '%Y%m') = #{date_params}").count
    @mobile_documents = TempDocument.from_mobile.where("DATE_FORMAT(created_at, '%Y%m') = #{date_params}").count
  end
end
