# -*- encoding : UTF-8 -*-
class Admin::PreAssignmentDeliveriesController < Admin::AdminController
  # GET /admin/pre_assignment_deliveries
  def index
    @pre_assignment_deliveries = PreAssignmentDelivery.search(search_terms(params[:pre_assignment_delivery_contains])).order(sort_column => sort_direction)

    @pre_assignment_deliveries_count = @pre_assignment_deliveries.count

    @pre_assignment_deliveries = @pre_assignment_deliveries.page(params[:page]).per(params[:per_page])
  end


  # GET /admin/pre_assignment_deliveries/:id
  def show
    @delivery = PreAssignmentDelivery.find_by_number(params[:id])
    raise ActiveRecord::RecordNotFound unless @delivery
  end

  private


  def sort_column
    params[:sort] || 'number'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end
