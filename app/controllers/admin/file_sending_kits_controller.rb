# -*- encoding : UTF-8 -*-
class Admin::FileSendingKitsController < Admin::AdminController
  before_filter :load_organization, :load_file_sending_kit

  layout :nil_layout

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if @file_sending_kit.update_attributes(params[:file_sending_kit])
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to admin_organization_path(@organization) }
      else
        format.json{ render json: @file_sending_kit.errors.to_json, status: :unprocessable_entity }
        format.html{ render action: :edit }
      end
    end
  end

  def select
  end

  def generate
    without_shipping_address = []
    clients_data = []
    @file_sending_kit.organization.customers.active.asc(:code).each do |client|
      value = params[:users]["#{client.id}"][:is_checked] rescue nil
      if value == 'true'
        without_shipping_address << client unless client.addresses.for_shipping.first
        clients_data << { :user => client, :start_month => params[:users]["#{client.id}"][:start_month].to_i, :offset_month => params[:users]["#{client.id}"][:offset_month].to_i }
      end
    end

    is_logo_present = true
    is_logo_present = false unless File.file?(File.join([Rails.root,'public',@file_sending_kit.logo_path]))
    is_logo_present = false unless File.file?(File.join([Rails.root,'public',@file_sending_kit.left_logo_path]))
    is_logo_present = false unless File.file?(File.join([Rails.root,'public',@file_sending_kit.right_logo_path]))

    if without_shipping_address.count == 0 && is_logo_present
      FileSendingKitGenerator::generate clients_data, @file_sending_kit
      flash[:notice] = 'Généré avec succès.'
    else
      flash[:error] = ''
      if without_shipping_address.count != 0
        flash[:error] = "Le(s) client(s) suivant(s) n'ont(a) pas d'adresse de livraison :"
        without_shipping_address.each do |client|
          flash[:error] << "</br><a href='#{admin_user_path(client)}' target='_blank'>#{client.info}</a>"
        end
      end
      unless is_logo_present
        flash[:error] << "</br></br>" if without_shipping_address.count != 0
        flash[:error] << "Logo central introuvable.</br>" unless File.file?(File.join([Rails.root,'public',@file_sending_kit.logo_path]))
        flash[:error] << "Logo gauche introuvable.</br>" unless File.file?(File.join([Rails.root,'public',@file_sending_kit.left_logo_path]))
        flash[:error] << "Logo droite introuvable.</br>" unless File.file?(File.join([Rails.root,'public',@file_sending_kit.right_logo_path]))
      end
    end
    respond_to do |format|
      format.json{ render json: {}, status: :ok }
      format.html{ redirect_to admin_organization_path(@organization) }
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

private

  def load_file_sending_kit
    @file_sending_kit = @organization.find_or_create_file_sending_kit
  end

  def send_pdf(filename)
    filepath = File.join([Rails.root,'/files/kit/' + filename])
    if File.file? filepath
      send_file(filepath, type: 'application/pdf', filename: filename, x_sendfile: true)
    else
      render nothing: true, status: 404
    end
  end
end