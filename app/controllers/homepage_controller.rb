class HomepageController < ApplicationController

  layout "homepage"

  def index
    debugger
    @homepage = Homepage.first
    @page_types = PageType.by_position.all
    @slides = Slide.visible.by_position
    @cms_images = CmsImage.all
    @pavets = Pavet.visible.by_position
    @page_in_footer = Page.in_footer.visible.by_position
  end

end
