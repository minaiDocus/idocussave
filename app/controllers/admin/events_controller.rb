# -*- encoding : UTF-8 -*-
class Admin::EventsController < Admin::AdminController
  before_filter :filtered_user_ids, :only => %w(index)

  def index
    @events = Event.all
    
    beginning_date = Time.now - 1.day
    if !params[:beginning_date].blank?
      beginning_date = params[:beginning_date].to_time rescue Time.now - 1.day
    end
    
    ending_date = Time.now
    if !params[:ending_date].blank?
      ending_date = params[:ending_date].to_time rescue Time.now
    end
    
    if !params[:beginning_date].blank?
      @events = @events.where(:created_at.gt => beginning_date, :created_at.lt => ending_date)
    elsif !params[:ending_date].blank?
      @events = @events.where(:created_at.lt => ending_date)
    end
    
    @events = @events.where(:title => params[:title]) if !params[:title].blank?
    @events = @events.any_in(:user_id => @filtered_user_ids) if !@filtered_user_ids.empty?
    
    @events = @events.order_by(:created_at.desc).paginate :page => params[:page], :per_page => 50
  end

end
