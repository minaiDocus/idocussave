# -*- encoding : UTF-8 -*-
class Admin::FileSendingKitsController < Admin::AdminController
  before_filter :load_user, :load_file_sending_kit

  layout :nil_layout

  private

  def load_user
    @user = User.find params[:user_id]
  end

  def load_file_sending_kit
    @file_sending_kit = @user.find_or_create_file_sending_kit
  end

  def send_pdf(filename)
    filepath = File.join([Rails.root,'/files/kit/' + filename])
    if File.exist? filepath
      contents = File.open(filepath,'rb').read
      send_data(contents, type: 'application/pdf', filename: filename, x_sendfile: true)
    else
      render nothing: true, status: 404
    end
  end

  public

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if @file_sending_kit.update_attributes(params[:file_sending_kit])
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to admin_user_path(@user) }
      else
        format.json{ render json: @file_sending_kit.errors.to_json, status: :unprocessable_entity }
        format.html{ render action: :edit }
      end
    end
  end

  def select
  end

  def generate
    clients_data = []
    @file_sending_kit.user.clients.active.each do |client|
      value = params[:users]["#{client.id}"][:is_checked] rescue nil
      if value == "true"
        clients_data << { :user => client, :start_month => params[:users]["#{client.id}"][:start_month].to_i, :offset_month => params[:users]["#{client.id}"][:offset_month].to_i }
      end
    end

    FileSendingKitGenerator::generate clients_data, @file_sending_kit
    respond_to do |format|
      format.json{ render json: {}, status: :ok }
      format.html{ redirect_to admin_user_path(@user) }
    end
  end

  def folder
    send_pdf('folder.pdf')
  end

  def mail
    send_pdf('mail.pdf')
  end

  def label
    send_pdf('label.pdf')
  end
end