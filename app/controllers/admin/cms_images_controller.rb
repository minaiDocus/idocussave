class Admin::CmsImagesController < Admin::AdminController
  layout 'admin'
  skip_before_filter :verify_authenticity_token, :only => %w(create)

  def index
    @cms_images = CmsImage.all
  end

  def create
    @cms_image = CmsImage.new
    @cms_image.original_file_name = params[:files][0].original_filename
    @cms_image.content = params[:files][0].tempfile
    @cms_image.save

    data = [{ thumb: @cms_image.content.url(:thumb).to_s, url: @cms_image.content.url.to_s, name: @cms_image.name }]

    respond_to do |format|
      format.json{ render :json => data }
      # this one is for IE8 who is really dumb...
      format.html{ render :json => data }
    end
  end

  def destroy
    @cms_image = CmsImage.find params[:id]
    @cms_image.destroy
    redirect_to admin_cms_images_path
  end
end
