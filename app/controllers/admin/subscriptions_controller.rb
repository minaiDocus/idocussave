# -*- encoding : UTF-8 -*-
class Admin::SubscriptionsController < Admin::AdminController
  def index
    @subscription_options = SubscriptionOption.by_position
    user_ids = User.customers.active_at(Time.now).map(:id)
    @basic_package_count     = Subscription.where(:user_id.in => user_ids, is_basic_package_active:     true).count
    @mail_package_count      = Subscription.where(:user_id.in => user_ids, is_mail_package_active:      true).count
    @scan_box_package_count  = Subscription.where(:user_id.in => user_ids, is_scan_box_package_active:  true).count
    @retriever_package_count = Subscription.where(:user_id.in => user_ids, is_retriever_package_active: true).count
    @annual_package_count    = Subscription.where(:user_id.in => user_ids, is_annual_package_active:    true).count
  end
end
