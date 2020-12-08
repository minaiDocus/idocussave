# frozen_string_literal: true

class Admin::PreAssignmentDeliveriesController < Admin::AdminController
  # GET /admin/pre_assignment_deliveries
  def index
    case params[:software]
    when 'ibiza'
      ibiza_deliveries
    when 'exact_online'
      exact_online_deliveries
    when 'my_unisoft'
      my_unisoft_deliveries
    else
      ibiza_deliveries
    end

    @pre_assignment_deliveries_count = @pre_assignment_deliveries.count

    @pre_assignment_deliveries = @pre_assignment_deliveries.page(params[:page]).per(params[:per_page])
  end

  # GET /admin/pre_assignment_deliveries/:id
  def show
    @delivery = PreAssignmentDelivery.find params[:id]
  end

  private

  def ibiza_deliveries
    @pre_assignment_deliveries_software = 'Ibiza'
    @pre_assignment_deliveries = PreAssignmentDelivery.search(search_terms(params[:pre_assignment_delivery_contains])).ibiza.order(sort_column => sort_direction)
  end

  def exact_online_deliveries
    @pre_assignment_deliveries_software = 'Exact Online'
    @pre_assignment_deliveries = PreAssignmentDelivery.search(search_terms(params[:pre_assignment_delivery_contains])).exact_online.order(sort_column => sort_direction)
  end

  def my_unisoft_deliveries
    @pre_assignment_deliveries_software = 'My Unisoft'
    @pre_assignment_deliveries = PreAssignmentDelivery.search(search_terms(params[:pre_assignment_delivery_contains])).my_unisoft.order(sort_column => sort_direction)
  end

  def sort_column
    params[:sort] || 'id'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end
