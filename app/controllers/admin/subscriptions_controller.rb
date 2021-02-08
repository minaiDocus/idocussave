# frozen_string_literal: true

class Admin::SubscriptionsController < Admin::AdminController
  before_action :load_accounts_ids
  # GET /admin/subscriptions
  def index
    @mail_package_count      = Rails.cache.fetch('admin_report_mail_package_count', expires_in: 10.minutes) { Subscription.where(user_id: @accounts_ids).where("current_packages LIKE '%mail_option%'").count }
    @basic_package_count     = Rails.cache.fetch('admin_report_basic_package_count', expires_in: 10.minutes) { Subscription.where(user_id: @accounts_ids).where("current_packages LIKE '%ido_classique%'").count }
    @annual_package_count    = Rails.cache.fetch('admin_report_annual_package_count', expires_in: 10.minutes) { Subscription.where(user_id: @accounts_ids).where("current_packages LIKE '%annual%'").count }
    @pre_assignment_count    = Rails.cache.fetch('admin_report_pre_assignment_count', expires_in: 10.minutes) { Subscription.where(user_id: @accounts_ids).where("current_packages LIKE '%pre_assignment_option%'").count }
    @scan_box_package_count  = Rails.cache.fetch('admin_report_scan_box_package_count', expires_in: 10.minutes) { Subscription.where(user_id: @accounts_ids).where("current_packages LIKE '%scan%'").count }
    @retriever_package_count = Rails.cache.fetch('admin_report_retriever_package_count', expires_in: 10.minutes) { Subscription.where(user_id: @accounts_ids).where("current_packages LIKE '%retriever_option%'").count }
    @mini_package_count      = Rails.cache.fetch('admin_report_mini_package_count', expires_in: 10.minutes) { Subscription.where(user_id: @accounts_ids).where("current_packages LIKE '%ido_mini%'").count }
    @micro_package_count     = Rails.cache.fetch('admin_report_micro_package_count', expires_in: 10.minutes) { Subscription.where(user_id: @accounts_ids).where("current_packages LIKE '%ido_micro%'").count }
    @nano_package_count      = Rails.cache.fetch('admin_report_nano_package_count', expires_in: 10.minutes) { Subscription.where(user_id: @accounts_ids).where("current_packages LIKE '%ido_nano%'").count }

    params[:per_page] ||= 50
    statistics = order(StatisticsManager.get_compared_subscription_statistics(statistic_params))
    @organization_count = statistics.size
    @statistics = Kaminari.paginate_array(statistics).page(params[:page]).per(params[:per_page])
    @statistics_total = calculate_total_of statistics

    respond_to do |format|
      format.html
      format.xls do
        filename = "Reporting_forfaits_iDocus_#{I18n.l(statistic_params[:first_period], format: '%b%y').titleize}_#{I18n.l(statistic_params[:second_period], format: '%b%y').titleize}.xls"
        send_data Subscription::StatisticsToXls.new(statistics).execute, type: 'application/vnd.ms-excel', filename: filename
      end
    end
  end

  def accounts
    accounts = User.where(id: @accounts_ids).joins(:subscription)

    case params[:type]
    when 'mail_package'
      data_accounts = Rails.cache.fetch('admin_report_mail_package_accounts', expires_in: 10.minutes) { accounts.merge(Subscription.where("current_packages LIKE '%mail_option%'")) }
    when 'basic_package'
      data_accounts = Rails.cache.fetch('admin_report_basic_package_accounts', expires_in: 10.minutes) { accounts.merge(Subscription.where("current_packages LIKE '%ido_classique%'")) }
    when 'annual_package'
      data_accounts = Rails.cache.fetch('admin_report_annual_package_accounts', expires_in: 10.minutes) { accounts.merge(Subscription.where("current_packages LIKE '%annual%'")) }
    when 'pre_assignment_active'
      data_accounts = Rails.cache.fetch('admin_report_pre_assignment_accounts', expires_in: 10.minutes) { accounts.merge(Subscription.where("current_packages LIKE '%pre_assignment_option%'")) }
    when 'scan_box_package'
      data_accounts = Rails.cache.fetch('admin_report_scan_box_package_accounts', expires_in: 10.minutes) { accounts.merge(Subscription.where("current_packages LIKE '%scan%'")) }
    when 'retriever_package'
      data_accounts = Rails.cache.fetch('admin_report_retriever_package_accounts', expires_in: 10.minutes) { accounts.merge(Subscription.where("current_packages LIKE '%retriever_option%'")) }
    when 'mini_package'
      data_accounts = Rails.cache.fetch('admin_report_mini_package_accounts', expires_in: 10.minutes) { accounts.merge(Subscription.where("current_packages LIKE '%ido_mini%'")) }
    when 'micro_package'
      data_accounts = Rails.cache.fetch('admin_report_micro_package_accounts', expires_in: 10.minutes) { accounts.merge(Subscription.where("current_packages LIKE '%ido_micro%'")) }
    when 'nano_package'
      data_accounts = Rails.cache.fetch('admin_report_nano_package_accounts', expires_in: 10.minutes) { accounts.merge(Subscription.where("current_packages LIKE '%ido_nano%'")) }
    else
      data_accounts = []
    end

    render partial: '/admin/subscriptions/accounts', layout: false, locals: { data_accounts: data_accounts }
  end

  private

  def load_accounts_ids
    @accounts_ids = []
    Organization.billed.each do |org|
      @accounts_ids += org.customers.active_at(Time.now).pluck(:id)
    end
    @accounts_ids.flatten!
  end

  def statistic_params
    options = { organization: params[:organization] }
    options[:first_period]  = (params[:first_period].present? ? params[:first_period].to_date : 1.month.ago)
    options[:second_period] = (params[:second_period].present? ? params[:second_period].to_date : Date.today)
  rescue StandardError
    options[:first_period]  = 1.month.ago.to_date
    options[:second_period] = Date.today
  ensure
    return options
  end

  def calculate_total_of(statistics)
    {
      basic_package: statistics.inject(0) { |sum, s| sum + s.options[:basic_package].to_i },
      basic_package_diff: statistics.inject(0) { |sum, s| sum + s.options[:basic_package_diff].to_i },
      mail_package: statistics.inject(0) { |sum, s| sum + s.options[:mail_package].to_i },
      mail_package_diff: statistics.inject(0) { |sum, s| sum + s.options[:mail_package_diff].to_i },
      scan_box_package: statistics.inject(0) { |sum, s| sum + s.options[:scan_box_package].to_i },
      scan_box_package_diff: statistics.inject(0) { |sum, s| sum + s.options[:scan_box_package_diff].to_i },
      retriever_package: statistics.inject(0) { |sum, s| sum + s.options[:retriever_package].to_i },
      retriever_package_diff: statistics.inject(0) { |sum, s| sum + s.options[:retriever_package_diff].to_i },
      mini_package: statistics.inject(0) { |sum, s| sum + s.options[:mini_package].to_i },
      mini_package_diff: statistics.inject(0) { |sum, s| sum + s.options[:mini_package_diff].to_i },
      micro_package: statistics.inject(0) { |sum, s| sum + s.options[:micro_package].to_i },
      micro_package_diff: statistics.inject(0) { |sum, s| sum + s.options[:micro_package_diff].to_i },
      nano_package: statistics.inject(0) { |sum, s| sum + s.options[:nano_package].to_i },
      nano_package_diff: statistics.inject(0) { |sum, s| sum + s.options[:nano_package_diff].to_i },
      annual_package: statistics.inject(0) { |sum, s| sum + s.options[:annual_package].to_i },
      annual_package_diff: statistics.inject(0) { |sum, s| sum + s.options[:annual_package_diff].to_i },
      upload: statistics.inject(0) { |sum, s| sum + s.consumption[:upload].to_i },
      scan: statistics.inject(0) { |sum, s| sum + s.consumption[:scan].to_i },
      dematbox_scan: statistics.inject(0) { |sum, s| sum + s.consumption[:dematbox_scan].to_i },
      retriever: statistics.inject(0) { |sum, s| sum + s.consumption[:retriever].to_i },
      customers: statistics.inject(0) { |sum, s| sum + s.customers&.size.to_i },
      new_customers: statistics.inject(0) { |sum, s| sum + s.try(:new_customers)&.size.to_i },
      closed_customers: statistics.inject(0) { |sum, s| sum + s.try(:closed_customers)&.size.to_i }
    }
  end

  def sort_column
    params[:sort] || 'organization_name'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'asc'
  end
  helper_method :sort_direction

  def order(statistics)
    attribute = sort_column.to_s.split('.')[0]
    h_value = sort_column.to_s.split('.')[1] || nil
    if h_value.nil?
      if attribute == 'customers' || attribute == 'new_customers' || attribute == 'closed_customers'
        result = statistics.sort { |a, b| a.send(attribute)&.size.to_i <=> b.send(attribute)&.size.to_i }
      else
        result = statistics.sort { |a, b| a.send(attribute) <=> b.send(attribute) }
      end
    else
      result = statistics.sort { |a, b| a.send(attribute)[h_value.to_sym] <=> b.send(attribute)[h_value.to_sym] }
    end

    sort_direction == 'desc' ? result.reverse! : result
  end
end
