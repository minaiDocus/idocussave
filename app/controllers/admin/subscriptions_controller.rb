# -*- encoding : UTF-8 -*-
class Admin::SubscriptionsController < Admin::AdminController
  # GET /admin/subscriptions
  def index
    user_ids = Rails.cache.fetch('admin_report_user_ids', expires_in: 10.minutes) { User.customers.active_at(Time.now).pluck(:id) }


    @stamp_count             = Rails.cache.fetch('admin_report_stamp_count', expires_in: 10.minutes) { Subscription.where(user_id: user_ids, is_stamp_active:  true).count }
    @mail_package_count      = Rails.cache.fetch('admin_report_mail_package_count', expires_in: 10.minutes) { Subscription.where(user_id: user_ids, is_mail_package_active:      true).count }
    @basic_package_count     = Rails.cache.fetch('admin_report_basic_package_count', expires_in: 10.minutes) { Subscription.where(user_id: user_ids, is_basic_package_active:     true).count }
    @annual_package_count    = Rails.cache.fetch('admin_report_annual_package_count', expires_in: 10.minutes) { Subscription.where(user_id: user_ids, is_annual_package_active:    true).count }
    @pre_assignment_count    = Rails.cache.fetch('admin_report_pre_assignment_count', expires_in: 10.minutes) { Subscription.where(user_id: user_ids, is_pre_assignment_active:    true).count }
    @scan_box_package_count  = Rails.cache.fetch('admin_report_scan_box_package_count', expires_in: 10.minutes) { Subscription.where(user_id: user_ids, is_scan_box_package_active:  true).count }
    @retriever_package_count = Rails.cache.fetch('admin_report_retriever_package_count', expires_in: 10.minutes) { Subscription.where(user_id: user_ids, is_retriever_package_active: true).count }
    @mini_package_count      = Rails.cache.fetch('admin_report_mini_package_count', expires_in: 10.minutes) { Subscription.where(user_id: user_ids, is_mini_package_active: true).count }
    @micro_package_count     = Rails.cache.fetch('admin_report_micro_package_count', expires_in: 10.minutes) { Subscription.where(user_id: user_ids, is_micro_package_active: true).count }

    params[:per_page] ||= 50
    statistics =  StatisticsManager.get_compared_subscription_statistics(statistic_params)
    @organization_count = statistics.size
    @statistics = Kaminari.paginate_array(statistics).page(params[:page]).per(params[:per_page])

    respond_to do |format|
      format.html  
      format.xls do
        filename = "Reporting_forfaits_iDocus_#{I18n.l(statistic_params[:first_period], format: "%b%y").titleize}_#{I18n.l(statistic_params[:second_period], format: "%b%y").titleize}.xls"
        send_data SubscriptionStatisticsToXls.new(statistics).execute, type: 'application/vnd.ms-excel', filename: filename
      end
    end
  end

  private

  def statistic_params
    begin
      options = { organization: params[:organization] }
      options[:first_period]  = (params[:first_period].present? ? params[:first_period].to_date : 1.month.ago)
      options[:second_period] = (params[:second_period].present? ? params[:second_period].to_date : Date.today)
    rescue
      options[:first_period]  = 1.month.ago.to_date
      options[:second_period] = Date.today
    ensure
      return options
    end
  end

end
