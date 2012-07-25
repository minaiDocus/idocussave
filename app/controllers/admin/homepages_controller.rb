# -*- encoding : UTF-8 -*-
class Admin::HomepagesController < Admin::AdminController

  before_filter :load_page, :only => %w(edit update destroy)

protected

  def load_page
   @homepage = Homepage.find params[:id]
  end

public

  def index
    @homepage = Homepage.first rescue Homepage.new
    @slides = Slide.all.by_position rescue nil
    @pavets = Pavet.all.by_position rescue nil
  end

  def new
    @homepage = Homepage.new
  end

  def create
    @homepage = Homepage.new params[:homepage]
    
    if @homepage.save
      redirect_to admin_homepages_path
    else
      render :action => "new"
    end
  end

  def edit
  end

  def update
    if @homepage.update_attributes params[:homepage]
      redirect_to admin_homepages_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @homepage.destroy
    redirect_to admin_homepages_path
  end
  
end
