class Admin::CsvOutputtersController < Admin::AdminController
  layout :nil_layout

  def show
    @user = User.find params[:user_id]
    @csv_outputter = @user.csv_outputter!
  end
end
