# -*- encoding : UTF-8 -*-
class Admin::CmsImagesController < Admin::AdminController
  
  skip_before_filter :verify_authenticity_token, :only => %w(create)

  def index
    @cms_images = CmsImage.all
  end

  def create
    @cms_image = CmsImage.new
    @cms_image.content = params[:file] || params[:qqfile]
    @cms_image.save

    respond_to do |format|
      format.json{ render :json => {:success => true, :url => @cms_image.content.url.to_s} }
      # this one is for IE8 who is really dumb...
      format.html{ render :json => {:success => true, :url => @cms_image.content.url.to_s} }
    end
  end

  def destroy
    @cms_image = CmsImage.find params[:id]
    @cms_image.destroy
    redirect_to admin_cms_images_path
  end
end
