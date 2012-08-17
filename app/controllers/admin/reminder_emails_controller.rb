# -*- encoding : UTF-8 -*-
class Admin::ReminderEmailsController < Admin::AdminController
  before_filter :load_user

  layout :nil_layout

  private

  def load_user
    @user = User.find params[:user_id]
  end

  public

  def index
    @reminder_emails = @user.reminder_emails
  end

  def preview
    @reminder_email = @user.reminder_emails.find params[:id]
  end

  def edit_multiple
  end

  def update_multiple
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to admin_user_path(@user) }
      else
        format.json{ render json: @user.errors.to_json, status: :unprocessable_entity }
        format.html{ render action: 'edit_multiple' }
      end
    end
  end
end