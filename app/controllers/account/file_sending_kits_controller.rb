# frozen_string_literal: true

class Account::FileSendingKitsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_file_sending_kit

  # GET /account/organizations/:organization_id/file_sending_kit/edit
  def edit; end

  # PUT /account/organizations/:organization_id/file_sending_kit
  def update
    if @file_sending_kit.update(file_sending_kit_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'file_sending_kit')
    else
      render 'edit'
    end
  end

  # GET /account/organizations/:organization_id/file_sending_kit/select
  def select; end

  # POST /account/organizations/:organization_id/file_sending_kit/generate
  def generate
    without_shipping_address = []
    clients_data = []
    @file_sending_kit.organization.customers.active.order(code: :asc).each do |client|
      value = begin
                params[:users][client.id.to_s][:is_checked]
              rescue StandardError
                nil
              end
      next unless value == 'true'

      unless client.paper_set_shipping_address && client.paper_return_address
        without_shipping_address << client
      end
      clients_data << { user: client, start_month: params[:users][client.id.to_s][:start_month].to_i, offset_month: params[:users][client.id.to_s][:offset_month].to_i }
    end

    is_logo_present = true
    unless File.file?(File.join([Rails.root, 'public', @file_sending_kit.logo_path]))
      is_logo_present = false
    end
    unless File.file?(File.join([Rails.root, 'public', @file_sending_kit.left_logo_path]))
      is_logo_present = false
    end
    unless File.file?(File.join([Rails.root, 'public', @file_sending_kit.right_logo_path]))
      is_logo_present = false
    end

    if without_shipping_address.count == 0 && is_logo_present
      FileSendingKitGenerator.generate clients_data, @file_sending_kit, (params[:one_workshop_labels_page_per_customer] == '1')
      flash[:notice] = 'Généré avec succès.'
    else
      errors = []
      if without_shipping_address.count != 0
        errors << "Les clients suivants n'ont pas d'adresse de livraison et/ou du kit :"
        without_shipping_address.each do |client|
          errors << "</br><a href='#{account_organization_customer_path(@organization, client)}' target='_blank'>#{client.info}</a>"
        end
      end
      unless is_logo_present
        errors << '</br></br>' if without_shipping_address.count != 0
        unless File.file?(File.join([Rails.root, 'public', @file_sending_kit.logo_path]))
          errors << 'Logo central introuvable.</br>'
        end
        unless File.file?(File.join([Rails.root, 'public', @file_sending_kit.left_logo_path]))
          errors << 'Logo gauche introuvable.</br>'
        end
        unless File.file?(File.join([Rails.root, 'public', @file_sending_kit.right_logo_path]))
          errors << 'Logo droite introuvable.</br>'
        end
      end

      flash[:error] = errors.join(' ') if errors.any?
    end
    redirect_to account_organization_path(@organization, tab: 'file_sending_kit')
  end

  # GET /account/organizations/:organization_id/file_sending_kit/folders
  def folders
    send_pdf('folders.pdf')
  end

  # GET /account/organizations/:organization_id/file_sending_kit/mails
  def mails
    send_pdf('mails.pdf')
  end

  # GET /account/organizations/:organization_id/file_sending_kit/customer_labels
  def customer_labels
    send_pdf('customer_labels.pdf')
  end

  # GET /account/organizations/:organization_id/file_sending_kit/workshop_labels
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
      render body: nil, status: 404
    end
  end
end
