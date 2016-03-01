# -*- encoding : UTF-8 -*-
class Admin::OrdersController < Admin::AdminController
  helper_method :sort_column, :sort_direction, :order_contains

  def index
    @orders = search(order_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

private

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def order_contains
    @contains ||= {}
    if params[:order_contains] && @contains.blank?
      @contains = params[:order_contains].delete_if do |key,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :order_contains

  def search(contains)
    orders = Order.all
    user_ids = []
    if params[:order_contains] && params[:order_contains][:user_code].present?
      user_ids = User.where(code: /#{Regexp.quote(params[:order_contains][:user_code])}/i).distinct(:_id)
    end
    orders = orders.where(created_at:            contains[:created_at])            if contains[:created_at].present?
    orders = orders.any_in(user_id:              user_ids)                         if user_ids.any?
    orders = orders.where(type:                  contains[:type])                  if contains[:type].present?
    orders = orders.where(price_in_cents_wo_vat: contains[:price_in_cents_wo_vat]) if contains[:price_in_cents_wo_vat].present?
    orders = orders.where(state:                 contains[:state])                 if contains[:state].present?
    orders
  end
end
