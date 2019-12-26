# frozen_string_literal: true

class PaperSetOrdersController < PaperProcessesController
  # GET /paper_set_orders
  def index
    @orders = Order.paper_sets.billed
    @orders = Order.search_for_collection(@orders, search_terms(params[:order_contains]))
    @orders_count = @orders.count
    @orders = @orders.joins(:user).select('orders.*, users.code as user_code, users.company as company, users.id as user_id').order("#{sort_column} #{sort_direction}").page(params[:page]).per(params[:per_page])
  end

  private

  def sort_column
    if params[:sort].in? %w[created_at id user_code state]
      params[:sort]
    else
      'created_at'
    end
  end
  helper_method :sort_column

  def sort_direction
    if params[:direction].in? %w[asc desc]
      params[:direction]
    else
      'desc'
    end
  end
  helper_method :sort_direction
end
