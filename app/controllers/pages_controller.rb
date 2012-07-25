# -*- encoding : UTF-8 -*-
class PagesController < ApplicationController

  before_filter :load_page, :only => %w(show)

protected

  def load_page
    @page = Page.find_by_slug params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Page, params[:id]) if @page.nil?
    @page_type = PageType.where(:number => @page.content_type).first
    @page_types = PageType.by_position.all
    @all_page = Page.where(:content_type => @page.content_type).visible.by_position
    @page_in_footer = Page.in_footer.visible.by_position.all
    @cms_images = CmsImage.all
  end

public

  def show
  end
end
