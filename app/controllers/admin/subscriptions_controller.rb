# -*- encoding : UTF-8 -*-
class Admin::SubscriptionsController < Admin::AdminController
  # GET /admin/subscriptions
  def index
    user_ids = User.customers.active_at(Time.now).pluck(:id)

    @subscription_options    = SubscriptionOption.by_position

    @stamp_count             = Subscription.where(user_id: user_ids, is_stamp_active:             true).count
    @mail_package_count      = Subscription.where(user_id: user_ids, is_mail_package_active:      true).count
    @basic_package_count     = Subscription.where(user_id: user_ids, is_basic_package_active:     true).count
    @annual_package_count    = Subscription.where(user_id: user_ids, is_annual_package_active:    true).count
    @pre_assignment_count    = Subscription.where(user_id: user_ids, is_pre_assignment_active:    true).count
    @scan_box_package_count  = Subscription.where(user_id: user_ids, is_scan_box_package_active:  true).count
    @retriever_package_count = Subscription.where(user_id: user_ids, is_retriever_package_active: true).count
  end
end
