class Admin::OrdersController < Admin::AdminController

  before_filter :load_model, :only => %w(show edit edit_option update update_option destroy)

  include Admin::BaseAdminMixin

protected
  
  def get_documents user, order
    Dir.chdir("#{Rails.root}/tmp/input_pdf_manuel/")
    
    file_names = []
    Dir.foreach("./") { |file_name|
      file_names << file_name.sub(/.pdf/i,'') if file_name.match(/.pdf/i)
      File.rename(file_name, file_name.sub(/.PDF/,'.pdf')) if file_name.match(/.PDF/)
    }
    
    doc_names = []
    params[:document_names].split(/\s*,\s*/).each do |doc_name|
      doc_names << doc_name
    end
    
    valid_names = []
    doc_names.each do |doc_name|
      file_names.each do |file_name|
        if doc_name.match(/[*]/)
          valid_names << file_name if file_name.match(/#{doc_name.sub('*','(.*)')}/i)
        else
          valid_names << file_name if file_name.match(/\A#{doc_name}\z/i)
        end
      end
    end

    valid_names.each do |file_name|
      number = order.packs.count + 1
      File.rename("#{file_name}.pdf","#{order.waybill_number}_#{number}.pdf")
    
      pack = Pack.new
      pack.order = order
      pack.name = file_name.gsub('_',' ')
      pack.users << user
      pack.save!
      pack.get_document "#{order.waybill_number}_#{number}"

      params[:share_with].split(', ').each do |other|
        observer = User.find_by_email other
        unless observer.nil? && observer.id != user.id
          pack.users << observer
        end
      end
      pack.save!
  
      tags = [" "]
      params[:tags].gsub('*','').downcase.split.each do |tag|
        tags << tag
      end

      pack.documents.each do |document|
        document_tag = DocumentTag.new
        document_tag.document = document.id
        document_tag.user = user.id
        g_tags = document_tag.generate
        document_tag.name += tags.join(' ')
        document_tag.save!
        params[:share_with].split(', ').each do |other|
          observer = User.find_by_email other rescue nil
          unless observer.nil?
            document_tag = DocumentTag.new
            document_tag.document = document.id
            document_tag.user = observer.id
            document_tag.name = g_tags + tags.join(' ')
            document_tag.save!
          end
        end
      end
    end
    order.save!
  end

public

  def index
    @orders = Order.all
  
    @users = User.all
    @users = @users.where(:email => /\w*#{params[:email]}\w*/) if !params[:email].blank?
    @users = @users.where(:first_name => /\w*#{params[:first_name]}\w*/) if !params[:first_name].blank?
    @users = @users.where(:last_name => /\w*#{params[:last_name]}\w*/) if !params[:last_name].blank?
    @users = @users.where(:company => /\w*#{params[:company]}\w*/) if !params[:company].blank?
    @users = @users.where(:code => /\w*#{params[:code]}\w*/) if !params[:code].blank?
    user_ids = @users.entries.collect{|u| u.id}
    
    @orders = @orders.where(:number => params[:number]) if !params[:number].blank?
    @orders = @orders.any_in(:user_id => user_ids).order_by(:number.desc, :created_at.asc).paginate :page => params[:page], :per_page => 50
    
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def model_class
    Order
  end

  def new
    @order = Order.new
  end

  def create
    user = User.find_by_email params[:email]
    order = Order.new
    order.user = user
    order.manual = true
    if params[:prescriber_email]
      order.prescriber = user if user = User.find_by_email(params[:prescriber_email])
    end
    order.pay!
    
    get_documents user, order
    flash[:notice] = "Crée avec succès."
    
    redirect_to admin_orders_path
  end
  
  def update
    message = ""
  
    order = Order.find params[:id]
    user = order.user
    
    unless params[:prescriber_email].blank?
      if prescriber = User.find_by_email(params[:prescriber_email])
        if prescriber.reporting && prescriber.reporting.clients.include?(user)
          prescriber.reporting.order_add order unless prescriber.reporting.order_ids.include?(order.id)
        else
          message += "L'utilisteur #{order.user.email} n'est pas client de #{prescriber.email}."
        end
      end
    else
      reporting = Reporting.where(:order_ids => order.id).entries
      reporting.each do |r|
        r.order_del order
      end
    end
    
    if get_documents user, order
      message += "Modifiée avec succès."
    end
    flash[:notice] = message
    
    redirect_to admin_orders_path
  end
  
  def update_prescriber
    order_ids = []
    nb = 0
    50.times do
      id = "id_#{nb}"
      if params[id]
        order_ids << params[id]
      end
      nb += 1
    end
  
    user = nil
    user = User.find_by_email(params[:prescriber_email]) unless params[:prescriber_email].blank?
  
    unless order_ids.empty?
      orders = Order.any_in(:_id => order_ids).entries
      unless orders.empty?
        orders.each do |order|
          reporting = Reporting.where(:order_ids => order.id).first
          if !user && reporting
            reporting.order_del order
            reporting.save
          elsif user
            if reporting && reporting.user != user
              reporting.order_del order
              reporting.save
            end
            user.reporting = Reporting.create unless user.reporting
            user.reporting.orders += orders
            user.reporting.save
            user.save
          end
        end
      end
      flash[:notice] = "Modifiée avec succès."
    else
      flash[:notice] = "Aucune commande séléctionner."
    end
    
    redirect_to admin_orders_path
  end

  def destroy
    @order.packs.each do |pack|
      pack.documents.each do |document|
        url = document.content.url(:thumb)
        url = url.split('/')
        cmd = "cd #{Rails.root}/public/system/contents/ && rm -r #{url[3]}"
        system(cmd)
        document.document_tag.delete if document.document_tag
      end
    end
    @order.delete
    flash[:notice] = "Supprimée avec succès."
    
    redirect_to admin_document_orders_path
  end

  def edit_option
  end
  
  def update_option
    @product = Product.find(params[:product_id])
    option_ids = []
    p  = Proc.new do |group, block|
      if group.subgroups
        group.subgroups.each do |group|
          block.call(group, block)
        end
      end
      if params["option_#{group.id}"]
        option_ids << params["option_#{group.id}"]
        if  ProductOption.find(params["option_#{group.id}"]).require_addresses == true
          require_addresses = true
        end
      elsif group.product_options
        group.product_options.each do |option|
          if params["option_#{group.id}_#{option.id}"]
            option_ids << params["option_#{group.id}_#{option.id}"]
            if  ProductOption.find(params["option_#{group.id}_#{option.id}"]).require_addresses == true
              require_addresses = true
            end
          end
        end
      end
    end
    
    @product.groups.where(:supergroup_id => nil).entries.each do |group|
      p.call(group, p)
    end
    
    @options = ProductOption.any_in(:_id => option_ids).entries
    
    @new_options = []
    @options.each do |option|
      quantity = 1
      if option.group && option.group.require
        quantity = option.group.require.product_options.any_in(:_id => @options.collect{|o| o.id}).first.quantity
      end
      new_option = option
      new_option.price_in_cents_wo_vat *= quantity
      @new_options << new_option
    end
    
    @order.set_product_order @product, @new_options
    
    event = Event.new
    event.title = "Changement d'options"
    event.description = "Changement d'options pour le produit \"#{@order.product_order.title}\" : #{@options.collect{|o| o.title}.join(' - ').downcase}"
    event.amount_in_cents = 0
    event.type_number = 0
    event.user = @order.user
    event.subscription = @order.subscription
    event.invoice = Invoice.create
    
    if @order.save && @order.user.save && event.save && event.invoice.save && @order.subscription.save
      redirect_to admin_order_path(@order)
    else
      redirect_to edit_option_admin_order_path(@order)
    end
  end
  
end