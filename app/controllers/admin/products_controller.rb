# -*- encoding : UTF-8 -*-
class Admin::ProductsController < Admin::AdminController

  before_filter :load_product, :only => %w(edit update destroy)

protected

  def load_product
    @product = Product.find_by_slug params[:id]
  end

public

  def index
    @products = Product.by_position.by_price_ascending.all
    @product_options = ProductOption.by_group.by_position.all
    @product_groups = ProductGroup.by_position.all
  end
  
  def new
    @product = Product.new
  end

  def create
    @product = Product.new params[:product]
    if @product.save
      redirect_to admin_products_path
    else
      render :action => "new"
    end
  end

  def edit
    @product = Product.find_by_slug params[:id]
  end

  def update
    if @product.update_attributes params[:product]
      redirect_to admin_products_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @product.destroy
    redirect_to admin_products_path
  end
  
end
