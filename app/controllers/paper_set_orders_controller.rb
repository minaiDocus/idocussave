# -*- encoding : UTF-8 -*-
class PaperSetOrdersController < PaperProcessesController
  # GET /paper_set_orders
  def index
    @orders = Order.paper_sets.billed
    @orders = Order.search_for_collection(@orders, search_terms(params[:order_contains]))
    @orders_count = @orders.count
    @orders = @orders.joins(:user).select("orders.*, users.code as user_code, users.company as company, users.id as user_id").order("#{sort_column} #{sort_direction}").page(params[:page]).per(params[:per_page])
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
