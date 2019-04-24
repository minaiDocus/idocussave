class Admin::CmsImagesController < Admin::AdminController
  skip_before_action :verify_authenticity_token, only: %w(create)


  # GET /admin/cms_images
  def index
    @cms_images = CmsImage.all
  end


  # POST /admin/cms_images
  def create
    @cms_image = CreateCmsImage.execute(params[:files][0].original_filename,
                                        params[:files][0].tempfile.path)

    data = [{ thumb: @cms_image.content.url(:thumb).to_s, url: @cms_image.content.url.to_s, name: @cms_image.name }]

    respond_to do |format|
      format.json { render json: { files: data } }
      format.html { render json: { files: data } }  # IE8 compatibility
    end
  end


  # DELETE /cms_images/:id
  def destroy
    @cms_image = CmsImage.find(params[:id])

    @cms_image.destroy

    redirect_to admin_cms_images_path
  end
end
