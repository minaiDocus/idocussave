# -*- encoding : UTF-8 -*-
class Admin::AccountBookTypesController < Admin::AdminController
  layout :nil_layout

  def index
    @user = User.find params[:user_id]
    @account_book_types = @user.account_book_types.unscoped.by_position
  end
end
