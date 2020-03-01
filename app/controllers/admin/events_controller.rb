# frozen_string_literal: true

class Admin::EventsController < Admin::AdminController
  # GET /admin/events
  def index
    @events = Event.search(search_terms(params[:event_contains])).includes(:user).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  # GET /admin/events/:id
  def show
    @event = Event.find(params[:id])

    render layout: false
  end

  private

  def sort_column
    params[:sort] || 'id'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end
