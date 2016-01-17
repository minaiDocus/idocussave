# -*- encoding : UTF-8 -*-
class Admin::ProductsController < Admin::AdminController
  before_filter :load_product, only: %w(edit update destroy)

  def index
    respond_to do |format|
      format.html do
        @products        = Product.by_position
        @product_options = ProductOption.by_group.by_position
        @product_groups  = ProductGroup.by_position
      end
      format.xls do
        data = SubscriptionStatsService.new.to_xls
        send_data data, type: 'application/vnd.ms-excel', filename: 'subscription_stats.xls'
      end
    end
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new product_params
    if @product.save
      flash[:notice] = 'Créé avec succès.'
      redirect_to admin_products_path
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @product.update product_params
      flash[:notice] = 'Modifié avec succès.'
      redirect_to admin_products_path
    else
      render action: 'edit'
    end
  end

  def destroy
    @product.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_products_path
  end

  def propagation_options
    @organization_names = Organization.all.asc(:name).map do |o|
      [o.name, o.id]
    end
  end

  def propagate
    req = OpenStruct.new(path: request.path, remote_ip: request.remote_ip)
    if params[:propagation_options][:scope] == 'all'
      User.customers.active.asc(:code).each do |customer|
        UpdateSubscription.execute(customer.subscription.id.to_s, {}, current_user.id.to_s, req)
      end
      flash[:notice] = 'Propagation en cours...'
    else
      organization = Organization.find(params[:propagation_options][:scope])
      if organization
        organization.customers.active.asc(:code).each do |customer|
          UpdateSubscription.execute(customer.subscription.id.to_s, {}, current_user.id.to_s, req)
        end
        flash[:notice] = 'Propagation en cours...'
      else
        flash[:error] = "L'organisation n'est pas valide."
      end
    end
    redirect_to admin_products_path
  end

private

  def load_product
    @product = Product.find_by_slug! params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Product, slug: params[:id]) unless @product
  end

  def product_params
    params.require(:product).permit(:title, :period_duration, :position)
  end
end
