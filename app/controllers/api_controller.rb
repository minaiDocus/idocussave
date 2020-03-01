# frozen_string_literal: true

class ApiController < ApplicationController
  before_action :authenticate_current_user
  before_action :verify_rights

  attr_reader :current_user

  def respond_with_unauthorized
    respond_to do |format|
      format.xml  { render xml:  '<message>Unauthorized</message>', status: 401 }
      format.json { render json: { message: 'Unauthorized' },       status: 401 }
    end
  end

  def respond_with_not_found
    respond_to do |format|
      format.xml  { render xml:  '<message>Not Found</message>',    status: 404 }
      format.json { render json: { message: 'Not Found' },          status: 404 }
    end
  end

  def respond_with_invalid_request(e = nil)
    title = 'Invalid Request'
    title += " : #{e.class}" if e
    respond_to do |format|
      format.xml  do
        if e
          content = view_context.content_tag :message do
            view_context.content_tag(:title, title) + view_context.content_tag(:description, e.message)
          end
        else
          content = view_context.content_tag :message, title
        end
        render xml: content, status: 400
      end
      format.json do
        content = if e
                    { message: title, description: e.message }
                  else
                    { message: title }
                  end
        render json: content, status: 400
      end
    end
  end

  private

  def authenticate_current_user
    unless authenticate_by_header || authenticate_by_params
      respond_to do |format|
        format.xml  { render xml:  '<message>Invalid API Token</message>', status: 401 }
        format.json { render json: { message: 'Invalid API Token' }, status: 401 }
      end
      nil
    end
  end

  def authenticate_by_header
    return true if @current_user

    authenticate_with_http_token do |token|
      @current_user = User.find_by_token(token)
    end
  end

  def authenticate_by_params
    return true if @current_user

    @current_user = User.find_by_token(params[:access_token])
  end

  def catch_error
    yield
  rescue ActionController::RoutingError,
         AbstractController::ActionNotFound,
         ActiveRecord::RecordNotFound
    respond_with_not_found
  rescue StandardError => e
    respond_to do |format|
      format.xml  { render xml:  '<message>Internal Error</message>', status: 500 }
      format.json { render json: { message: 'Internal Error' },       status: 500 }
    end
  end

  def verify_rights
    if controller_name == 'pre_assignments' && !@current_user.is_operator && !@current_user.is_admin
      respond_with_unauthorized
    end
  end
end
