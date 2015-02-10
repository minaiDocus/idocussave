# -*- encoding : UTF-8 -*-
class Admin::ProductGroupsController < Admin::AdminController
  before_filter :load_group, only: %w(edit update destroy)

  def new
    @product_group = ProductGroup.new
  end

  def create
    @product_group = ProductGroup.new params[:product_group]
    if @product_group.save
      flash[:notice] = 'Créé avec succès.'
      redirect_to admin_products_path
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @product_group.update_attributes params[:product_group]
      flash[:notice] = 'Modifié avec succès.'
      redirect_to admin_products_path
    else
      render action: 'edit'
    end
  end

  def destroy
    @product_group.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_products_path
  end

private

  def load_group
    @product_group = ProductGroup.find_by_slug params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(ProductGroup, params[:id]) unless @product_group
  end
end
