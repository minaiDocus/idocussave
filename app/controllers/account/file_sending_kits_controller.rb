# frozen_string_literal: true

class Account::FileSendingKitsController < Account::OrganizationController
  before_action :verify_rights
  before_action :load_file_sending_kit

  # GET /account/organizations/:organization_id/file_sending_kit/edit
  def edit; end

  def get_logo
    position = params[:position] || 'center'

    case position
      when 'center'
        filepath = @file_sending_kit.real_logo_path
      when 'left'
        filepath = @file_sending_kit.real_left_logo_path
      when 'right'
        filepath = @file_sending_kit.real_right_logo_path
    end

    if File.exist?(filepath)
      extension = File.extname(filepath).downcase
      send_file(filepath, type: 'application/pdf', filename: "#{position}_logo.#{extension}", x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # PUT /account/organizations/:organization_id/file_sending_kit
  def update
    @file_sending_kit.title             = params[:file_sending_kit][:title].strip
    @file_sending_kit.position          = params[:file_sending_kit][:position].strip
    @file_sending_kit.instruction       = params[:file_sending_kit][:instruction].strip
    @file_sending_kit.logo_height       = params[:file_sending_kit][:logo_height].strip
    @file_sending_kit.logo_width        = params[:file_sending_kit][:logo_width].strip
    @file_sending_kit.left_logo_height  = params[:file_sending_kit][:left_logo_height].strip
    @file_sending_kit.left_logo_width   = params[:file_sending_kit][:left_logo_width].strip
    @file_sending_kit.right_logo_height = params[:file_sending_kit][:right_logo_height].strip
    @file_sending_kit.right_logo_width  = params[:file_sending_kit][:right_logo_width].strip

    if CustomUtils.is_manual_paper_set_order?(@organization) && @file_sending_kit.save
      attach_images

      @file_sending_kit.reload

      @file_sending_kit.logo_path       = @file_sending_kit.cloud_center_logo_object.reload.path
      @file_sending_kit.left_logo_path  = @file_sending_kit.cloud_left_logo_object.reload.path
      @file_sending_kit.right_logo_path = @file_sending_kit.cloud_right_logo_object.reload.path
    else
      @file_sending_kit.logo_path       = params[:file_sending_kit][:logo_path].strip
      @file_sending_kit.left_logo_path  = params[:file_sending_kit][:left_logo_path].strip
      @file_sending_kit.right_logo_path = params[:file_sending_kit][:right_logo_path].strip
    end

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
    clients_data             = []
    manual_paper_set_order   = CustomUtils.is_manual_paper_set_order?(@organization)

    current_order = {}

    if manual_paper_set_order
      orders = []
      if params[:orders].any?
        params[:orders].each do |param_order|
          order_attributes           = param_order.permit(:user_id, :paper_set_folder_count, :paper_set_start_date, :paper_set_end_date)
          value = begin
                    params[:users][order_attributes[:user_id].to_s][:is_checked]
                  rescue StandardError
                    nil
                  end
          next unless value == 'true'

          order                      = Order.where(order_attributes).first || Order.new(order_attributes)
          order.type                 = 'paper_set'
          order.address              = order.user.paper_set_shipping_address.is_a?(Address) ? order.user.paper_set_shipping_address.try(:dup) : nil
          order.paper_return_address = order.user.paper_return_address.is_a?(Address) ? order.user.paper_return_address.try(:dup) : nil
          order.address_required     = false
          orders << order unless Order::PaperSet.new(order.user, order, order.persisted?).execute

          current_order[order_attributes[:user_id].to_s] = order.reload
        end
      end

      flash[:success] = 'Vos commandes de Kit envoi courrier ont été prises en comptes'
    end

    @file_sending_kit.organization.customers.active.order(code: :asc).each do |client|
      value = begin
                params[:users][client.id.to_s][:is_checked]
              rescue StandardError
                nil
              end
      next unless value == 'true'

      unless client.paper_set_shipping_address && client.paper_return_address
        without_shipping_address << client if !manual_paper_set_order
      end

      client.reload

      current_order[client.id.to_s] ||= client.orders.paper_sets.order(updated_at: :desc).first

      if client.orders.paper_sets.size > 0 && !current_order[client.id.to_s].try(:normal_paper_set_order?)
        clients_data << { user: client, start_month: current_order[client.id.to_s].periods_offset_start, offset_month: current_order[client.id.to_s].periods_count }
      else
        clients_data << { user: client, start_month: params[:users][client.id.to_s][:start_month].to_i, offset_month: params[:users][client.id.to_s][:offset_month].to_i }
      end

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
      Order::FileSendingKitGenerator.generate clients_data, @file_sending_kit, @organization.code.downcase, (params[:one_workshop_labels_page_per_customer] == '1')
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

    if manual_paper_set_order
      render json: {messahe: 'OK'}, status: 200
      # redirect_to folders_account_organization_file_sending_kit_path(@organization)
    else
      redirect_to account_organization_path(@organization, tab: 'file_sending_kit')
    end
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
    unless @user.is_admin || (CustomUtils.is_manual_paper_set_order?(@organization) && @user.orders.size > 0)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_file_sending_kit
    @file_sending_kit = @organization.find_or_create_file_sending_kit
  end

  def send_pdf(filename)
    filename = "#{@organization.code.downcase}_#{filename}"
    filepath = File.join([Rails.root, 'files', 'kit', filename])
    if File.file? filepath
      send_file(filepath, type: 'application/pdf', filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  def attach_images
    center_logo = params[:file_sending_kit][:center_logo]
    left_logo = params[:file_sending_kit][:left_logo]
    right_logo = params[:file_sending_kit][:right_logo]

    @file_sending_kit.cloud_center_logo.attach(io: File.open(center_logo.tempfile), filename: "center_logo_#{@file_sending_kit.id}.png", content_type: "image/png") if center_logo.present?
    @file_sending_kit.cloud_left_logo.attach(io: File.open(left_logo.tempfile), filename: "center_logo_#{@file_sending_kit.id}.png", content_type: "image/png") if left_logo.present?
    @file_sending_kit.cloud_right_logo.attach(io: File.open(right_logo.tempfile), filename: "center_logo_#{@file_sending_kit.id}.png", content_type: "image/png") if right_logo.present?
  end
end
