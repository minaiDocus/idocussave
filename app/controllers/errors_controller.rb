# -*- encoding : UTF-8 -*-
class ErrorsController < ApplicationController
  def routing
    if params[:a].match(/^system.*\/contents\//)
      raise ActionController::RoutingError.new('Not Found')
    else
      render '/404.html.haml', status: 404, layout: 'error'
    end
  end
end
