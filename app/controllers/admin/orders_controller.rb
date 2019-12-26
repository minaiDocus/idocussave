# frozen_string_literal: true

class Admin::OrdersController < Admin::AdminController
  helper_method :sort_column, :sort_direction

  # GET /admin/orders
  def index
    @order_contains = params[:order_contains]

    @orders = Order.search(search_terms(params[:order_contains])).order(sort_column => sort_direction).includes(:user, :organization, :address)

    @orders_count = @orders.count

    @orders = @orders.page(params[:page]).per(params[:per_page])
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
end
