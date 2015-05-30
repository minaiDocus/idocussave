# -*- encoding : UTF-8 -*-
class Admin::ProductOptionsController < Admin::AdminController
  before_filter :load_product_option, only: %w(edit update destroy)

  def new
    @product_option = ProductOption.new
  end

  def create
    @product_option = ProductOption.new product_option_params
    if @product_option.save
      flash[:notice] = 'Créé avec succès.'
      redirect_to admin_products_path
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @product_option.update product_option_params
      flash[:notice] = 'Modifié avec succès.'
      redirect_to admin_products_path
    else
      render action: 'edit'
    end
  end

  def destroy
    @product_option.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_products_path
  end

private

  def load_product_option
    @product_option = ProductOption.find_by_slug! params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(ProductOption, slug: params[:id]) unless @product_option
  end

  def product_option_params
    if params[:product_option][:action_names].present?
      params[:product_option][:action_names] = params[:product_option][:action_names].map(&:presence).compact
    end
    params.require(:product_option).permit(
      :name,
      :title,
      :description,
      :price_in_cents_wo_vat,
      :position,
      :duration,
      :quantity,
      :product_group,
      { action_names: [] },
      :notify,
      :is_default
    )
  end
end
