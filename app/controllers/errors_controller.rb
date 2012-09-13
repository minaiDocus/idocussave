# -*- encoding : UTF-8 -*-
class ErrorsController < ApplicationController
  def routing
    if params[:a].match(/^system\/contents\//)
      render :nothing => true, :status => 404
    else
      render "/404", :status => 404, :layout => "pages"
    end
  end
  
end
