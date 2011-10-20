class Admin::ProductOptionsController < Admin::AdminController

  before_filter :load_product_option, :only => %w(edit update destroy)

protected

  def load_product_option
    @product_option = ProductOption.find_by_slug params[:id]
  end

public

  def new
    @product_option = ProductOption.new
  end

  def create
    @product_option = ProductOption.new params[:product_option]
    if @product_option.save
      redirect_to admin_products_path
    else
      render :action => "new"
    end
  end

  def edit
  end

  def update
    if @product_option.update_attributes params[:product_option]
      redirect_to admin_products_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @product_option.destroy
    redirect_to admin_products_path
  end
end
