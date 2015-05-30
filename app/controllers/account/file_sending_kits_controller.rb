# -*- encoding : UTF-8 -*-
class Account::FileSendingKitsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_file_sending_kit

  def edit
  end

  def update
    if @file_sending_kit.update(file_sending_kit_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'file_sending_kit')
    else
      render 'edit'
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
        unless client.addresses.for_kit_shipping.first && client.addresses.for_shipping.first
          without_shipping_address << client
        end
        clients_data << { :user => client, :start_month => params[:users]["#{client.id}"][:start_month].to_i, :offset_month => params[:users]["#{client.id}"][:offset_month].to_i }
      end
    end

    is_logo_present = true
    is_logo_present = false unless File.file?(File.join([Rails.root,'public',@file_sending_kit.logo_path]))
    is_logo_present = false unless File.file?(File.join([Rails.root,'public',@file_sending_kit.left_logo_path]))
    is_logo_present = false unless File.file?(File.join([Rails.root,'public',@file_sending_kit.right_logo_path]))

    if without_shipping_address.count == 0 && is_logo_present
      FileSendingKitGenerator::generate clients_data, @file_sending_kit, (params[:one_workshop_labels_page_per_customer] == '1' ? true : false)
      flash[:notice] = 'Généré avec succès.'
    else
      flash[:error] = ''
      if without_shipping_address.count != 0
        flash[:error] = "Les clients suivants n'ont pas d'adresse de livraison et/ou du kit :"
        without_shipping_address.each do |client|
          flash[:error] << "</br><a href='#{account_organization_customer_path(@organization, client)}' target='_blank'>#{client.info}</a>"
        end
      end
      unless is_logo_present
        flash[:error] << "</br></br>" if without_shipping_address.count != 0
        flash[:error] << "Logo central introuvable.</br>" unless File.file?(File.join([Rails.root,'public',@file_sending_kit.logo_path]))
        flash[:error] << "Logo gauche introuvable.</br>" unless File.file?(File.join([Rails.root,'public',@file_sending_kit.left_logo_path]))
        flash[:error] << "Logo droite introuvable.</br>" unless File.file?(File.join([Rails.root,'public',@file_sending_kit.right_logo_path]))
      end
    end
    redirect_to account_organization_path(@organization, tab: 'file_sending_kit')
  end

  def folders
    send_pdf('folders.pdf')
  end

  def mails
    send_pdf('mails.pdf')
  end

  def customer_labels
    send_pdf('customer_labels.pdf')
  end

  def workshop_labels
    send_pdf('workshop_labels.pdf')
  end

private

  def verify_rights
    unless @user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_file_sending_kit
    @file_sending_kit = @organization.find_or_create_file_sending_kit
  end

  def file_sending_kit_params
    params.require(:file_sending_kit).permit(
      :title,
      :position,
      :instruction,
      :logo_path,
      :logo_height,
      :logo_width,
      :left_logo_path,
      :left_logo_height,
      :left_logo_width,
      :right_logo_path,
      :right_logo_height,
      :right_logo_width
    )
  end

  def send_pdf(filename)
    filepath = File.join([Rails.root, 'files', Rails.env, 'kit', filename])
    if File.file? filepath
      send_file(filepath, type: 'application/pdf', filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end
end
