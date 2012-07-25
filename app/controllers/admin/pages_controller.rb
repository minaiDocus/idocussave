# -*- encoding : UTF-8 -*-
class Admin::PagesController < Admin::AdminController

  before_filter :load_page, :only => %w(edit update destroy)

protected

  def load_page
    @page = Page.find_by_slug params[:id]
  end

public

  def index
    @page_types = PageType.by_position.all
    @pages = Page.by_position.all
    @homepage = Homepage.first
  end

  def new
    @page = Page.new
    1.times do
      page_content = @page.page_contents.build
      1.times { page_content.page_content_items.build }
    end
  end

  def create
    @page = Page.new params[:page]
    
    if @page.save
      redirect_to admin_pages_path
    else
      render :action => "new"
    end
  end

  def edit
  end

  def update
    if @page.update_attributes params[:page]
      redirect_to admin_pages_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @page.destroy
    redirect_to admin_pages_path
  end

  def update_is_invisible_status
    @page = Page.find params[:id]
    value = params[:value] == "false" ? false : true
    @page.is_invisible = value
    @page.save!

    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
      format.html{ redirect_to admin_pages_path }
    end
  end

end
