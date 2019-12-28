# frozen_string_literal: true

class ErrorsController < ApplicationController
  def routing
    raise ActionController::RoutingError, 'Not Found'
  end
end
