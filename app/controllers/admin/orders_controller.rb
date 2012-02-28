class Admin::OrdersController < Admin::AdminController

  before_filter :load_model, :only => %w(show edit edit_option update update_option destroy)
  before_filter :filtered_user_ids, :only => %w(index)

  include Admin::BaseAdminMixin

public

  def index
    @orders = Order.all
    
    @orders = @orders.where(:number => params[:number]) if !params[:number].blank?
    @orders = @orders.any_in(:user_id => @filtered_user_ids) if !@filtered_user_ids.empty?
    
    @orders = @orders.order_by(:number.desc, :created_at.desc).paginate :page => params[:page], :per_page => 50
    
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def model_class
    Order
  end

  def show
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
    if @order.update_attributes params[:order]
      respond_to do |format|
        format.json{ render :json => {}, :status => :ok }
        format.html{ redirect_to admin_orders_path, :notice => 'Modifiée avec succès.' }
      end
    else
      respond_to do |format|
        format.json{ render :json => {}, :status => :unprocessable_entity }
        format.html{ render :action => 'edit' }
      end
    end
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