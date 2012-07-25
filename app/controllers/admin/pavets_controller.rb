# -*- encoding : UTF-8 -*-
class Admin::PavetsController < Admin::AdminController

  before_filter :load_pavet, :only => %w(edit update destroy)

protected

  def load_pavet
   @pavet = Pavet.find params[:id]
  end

public
  
  def new
    @pavet = Pavet.new
  end
  
  def create
    @pavet = Pavet.new params[:pavet]
    
    if @pavet.save
      redirect_to admin_homepages_path
    else
      render :action => "new"
    end
  end

  def edit
  end
  
  def update
    if @pavet.update_attributes params[:pavet]
      redirect_to admin_homepages_path
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @pavet.destroy
    redirect_to admin_homepages_path
  end
  
  def update_is_invisible_status
    @pavet = Pavet.find params[:id]
    value = params[:value] == "false" ? false : true
    @pavet.is_invisible = value
    @pavet.save!

    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
      format.html{ redirect_to admin_homepages_path }
    end
  end

end
