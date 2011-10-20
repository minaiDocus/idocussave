class Admin::PageTypesController < Admin::AdminController
  
  before_filter :load_page, :only => %w(edit update destroy)

protected

  def load_page
    @page_type = PageType.find params[:id]
  end

public

  def new
    @page_type = PageType.new
  end

  def create
   @page_type = PageType.new params[:page_type]
   
   if @page_type.save
      redirect_to admin_pages_path
   else
      @new_page_type = @page_type
      render :action => "new"
   end
  end

  def edit
  end

  def update
    if @page_type.update_attributes params[:page_type]
      redirect_to admin_pages_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @page_type.destroy
    redirect_to admin_pages_path
  end

end
