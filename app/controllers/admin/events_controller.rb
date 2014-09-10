# -*- encoding : UTF-8 -*-
class Admin::EventsController < Admin::AdminController
  def index
    @events = search(event_contains).order([sort_column, sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def show
    @event = Event.find params[:id]
    render layout: false
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

  def event_contains
    @contains ||= {}
    if params[:event_contains] && @contains.blank?
      @contains = params[:event_contains].delete_if do |_,value|
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
  helper_method :event_contains

  def search(contains)
    events = Event.all
    if params[:user_contains].try(:[], :code).present?
      if params[:user_contains][:code].downcase.in?(%w(visiteur visitor))
        events = events.where(:user_id.exists => false)
      else
        user_ids = User.where(code: /#{Regexp.quote(params[:user_contains][:code])}/i).distinct(:_id)
        events = events.where(:user_id.in => user_ids)
      end
    end
    events = events.where(number:      contains[:number])      if contains[:number].present?
    events = events.where(created_at:  contains[:created_at])  if contains[:created_at].present?
    events = events.where(action:      contains[:action])      if contains[:action].present?
    events = events.where(target_type: contains[:target_type]) if contains[:target_type].present?
    events = events.where(target_name: /#{Regexp.quote(contains[:target_name])}/i) if contains[:target_name].present?
    events
  end
end
