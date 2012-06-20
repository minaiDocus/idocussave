class ErrorsController < ApplicationController
  def routing
    if params[:a].match(/^system\/contents\//)
      render :nothing => true, :status => 404
    else
      render :template => "404.html.haml", :status => 404, :layout => "pages"
    end
  end
  
end
