# -*- encoding : UTF-8 -*-
class Admin::PreAssignmentDeliveriesController < Admin::AdminController
  def index
    @pre_assignment_deliveries = search(pre_assignment_delivery_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def show
    @delivery = PreAssignmentDelivery.find_by_number params[:id]
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

  def pre_assignment_delivery_contains
    @contains ||= {}
    if params[:pre_assignment_delivery_contains] && @contains.blank?
      @contains = params[:pre_assignment_delivery_contains].delete_if do |_,value|
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
  helper_method :pre_assignment_delivery_contains

  def search(contains)
    deliveries = PreAssignmentDelivery.all
    deliveries = deliveries.where(created_at: contains[:created_at])                    if contains[:created_at].present?
    deliveries = deliveries.where(pack_name:  /#{Regexp.quote(contains[:pack_name])}/i) if contains[:pack_name].present?
    deliveries = deliveries.where(total_item: contains[:total_item].to_i)               if contains[:total_item].present?
    deliveries = deliveries.where(is_auto:    contains[:is_auto].to_i == 1)             if contains[:is_auto].present?
    deliveries = deliveries.where(state:      contains[:state])                         if contains[:state].present?
    deliveries
  end
end
