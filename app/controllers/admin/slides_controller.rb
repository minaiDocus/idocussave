class Admin::SlidesController < Admin::AdminController

  before_filter :load_slide, :only => %w(edit update destroy)

protected

  def load_slide
   @slide = Slide.find params[:id]
  end

public

  def new
    @slide = Slide.new
  end
  
  def create
    @slide = Slide.new params[:slide]
    
    if @slide.save
      redirect_to admin_homepages_path
    else
      render :action => "new"
    end
  end

  def edit
  end
  
  def update
    if @slide.update_attributes params[:slide]
      redirect_to admin_homepages_path
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @slide.destroy
    redirect_to admin_homepages_path
  end
  
  def update_is_invisible_status
    @slide = Slide.find params[:id]
    value = params[:value] == "false" ? false : true
    @slide.is_invisible = value
    @slide.save!

    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
      format.html{ redirect_to admin_homepages_path }
    end
  end

end
