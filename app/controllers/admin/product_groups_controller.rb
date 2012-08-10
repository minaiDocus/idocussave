# -*- encoding : UTF-8 -*-
class Admin::ProductGroupsController < Admin::AdminController

  before_filter :load_group, :only => %w(edit update destroy)

protected

  def load_group
    @product_group = ProductGroup.find_by_slug params[:id]
  end

public

  def index
    @product_groups = ProductGroup.by_position.all
  end

  def new
    @product_group = ProductGroup.new
  end

  def create
    @product_group = ProductGroup.new params[:product_group]
    if @product_group.save
      redirect_to admin_products_path
    else
      render :action => "new"
    end
  end

  def edit
  @product_group = ProductGroup.find_by_slug params[:id]
  end

  def update
    if @product_group.update_attributes params[:product_group]
      redirect_to admin_products_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @product_group.destroy
    redirect_to admin_products_path
  end
end
