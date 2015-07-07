# -*- encoding : UTF-8 -*-
class ComptaController < ApplicationController
  before_filter :authenticate
  before_filter :load_users

  def index
  end

  def show
    @user = @users.find_by_code params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(User, code: params[:id]) unless @user
  end

private

  def authenticate
    authenticate_or_request_with_http_basic do |name, password|
      Settings.compta_operators.select do |operator|
        operator['username'] == name && operator['password'] == password
      end.first.present?
    end
  end

  def load_users
    organization_ids = Organization.billed.map(&:id)
    user_ids = AccountBookType.where(:user_id.exists => true).compta_processable.distinct(:user_id)
    @users = User.where(:organization_id.in => organization_ids, :_id.in => user_ids).active.includes(:options)
  end
end
