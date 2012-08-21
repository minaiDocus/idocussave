# -*- encoding : UTF-8 -*-
module PagesHelper
  def footer_pages
    Page.visible.by_position.in_footer
  end

  def pages_type
    Page.visible.by_position.all_first_pages
  end

  def image_url_for_page param
    CmsImage.find_by_name(param.image.try(:name)).try(:content).try(:url) || ''
  end
end