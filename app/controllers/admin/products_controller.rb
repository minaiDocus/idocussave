# -*- encoding : UTF-8 -*-
class Admin::ProductsController < Admin::AdminController
  before_filter :load_product, only: %w(edit update destroy)

  def index
    @products        = Product.by_position
    @product_options = ProductOption.by_group.by_position
    @product_groups  = ProductGroup.by_position
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new params[:product]
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
    if @product.update_attributes params[:product]
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
    if params[:propagation_options][:scope] == 'all'
      User.customers.active.asc(:code).each do |customer|
        subscription = customer.find_or_create_scan_subscription
        UpdateSubscriptionService.new(subscription, {}, current_user).execute
      end
      flash[:notice] = 'Propagé avec succès.'
    else
      organization = Organization.find(params[:propagation_options][:scope])
      if organization
        organization.customers.active.asc(:code).each do |customer|
          subscription = customer.find_or_create_scan_subscription
          UpdateSubscriptionService.new(subscription, {}, current_user).execute
        end
        flash[:notice] = 'Propagé avec succès.'
      else
        flash[:error] = "L'organisation n'est pas valide."
      end
    end
    redirect_to admin_products_path
  end

private

  def load_product
    @product = Product.find_by_slug params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Product, params[:id]) unless @product
  end
end
