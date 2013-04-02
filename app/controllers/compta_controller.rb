# -*- encoding : UTF-8 -*-
class ComptaController < ApplicationController
  before_filter :authenticate
  before_filter :load_users

  def index
  end

  def show
    @user = @users.find_by_code params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(User, params[:id]) unless @user
  end

private

  def authenticate
    authenticate_or_request_with_http_basic do |name, password|
      [name, password].in? Compta::USERS
    end
  end

  def load_users
    organization_ids = Organization.not_test.distinct(:_id)
    user_ids = AccountBookType.compta_processable.any_in(organization_id: organization_ids).distinct(:client_ids).flatten
    @users = User.any_in(_id: user_ids)
  end
end
