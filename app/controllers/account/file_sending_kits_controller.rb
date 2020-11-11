# frozen_string_literal: true

class Account::FileSendingKitsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_file_sending_kit

  # GET /account/organizations/:organization_id/file_sending_kit/edit
  def edit; end

  # PUT /account/organizations/:organization_id/file_sending_kit
  def update
    @file_sending_kit.title             = params[:file_sending_kit][:title].strip
    @file_sending_kit.position          = params[:file_sending_kit][:position].strip
    @file_sending_kit.instruction       = params[:file_sending_kit][:instruction].strip
    @file_sending_kit.logo_path         = params[:file_sending_kit][:logo_path].strip
    @file_sending_kit.logo_height       = params[:file_sending_kit][:logo_height].strip
    @file_sending_kit.logo_width        = params[:file_sending_kit][:logo_width].strip
    @file_sending_kit.left_logo_path    = params[:file_sending_kit][:left_logo_path].strip
    @file_sending_kit.left_logo_height  = params[:file_sending_kit][:left_logo_height].strip
    @file_sending_kit.left_logo_width   = params[:file_sending_kit][:left_logo_width].strip
    @file_sending_kit.right_logo_path   = params[:file_sending_kit][:right_logo_path].strip
    @file_sending_kit.right_logo_height = params[:file_sending_kit][:right_logo_height].strip
    @file_sending_kit.right_logo_width  = params[:file_sending_kit][:right_logo_width].strip

    if @file_sending_kit.save
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

    error_logo = []
    unless File.exist?(@file_sending_kit.real_logo_path)
      error_logo << 'Logo central introuvable.</br>'
    end
    unless File.exist?(@file_sending_kit.real_left_logo_path)
      error_logo << 'Logo gauche introuvable.</br>'
    end
    unless File.exist?(@file_sending_kit.real_right_logo_path)
      error_logo << 'Logo droite introuvable.</br>'
    end

    if without_shipping_address.count == 0 && error_logo.empty?
      Order::FileSendingKitGenerator.generate clients_data, @file_sending_kit, (params[:one_workshop_labels_page_per_customer] == '1')
      flash[:notice] = 'Généré avec succès.'
    else
      errors = []
      if without_shipping_address.count != 0
        errors << "Les clients suivants n'ont pas d'adresse de livraison et/ou du kit :"
        without_shipping_address.each do |client|
          errors << "</br><a href='#{account_organization_customer_path(@organization, client)}' target='_blank'>#{client.info}</a>"
        end
      end
      if error_logo.any?
        errors << '</br></br>' if without_shipping_address.count != 0
        errors << error_logo.join(' ')
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

  def send_pdf(filename)
    filepath = File.join([Rails.root, 'files', 'kit', filename])
    if File.file? filepath
      send_file(filepath, type: 'application/pdf', filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end
end
