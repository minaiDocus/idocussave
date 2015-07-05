# -*- encoding : UTF-8 -*-
class ErrorsController < ApplicationController
  def routing
    raise ActionController::RoutingError.new('Not Found')
  end
end
