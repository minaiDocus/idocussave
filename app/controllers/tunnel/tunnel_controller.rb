class Tunnel::TunnelController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_page

  layout "tunnel"

  def index
  end

  protected
  
  def load_page
    @page_in_footer = Page.in_footer.by_position.visible
    @page_types = PageType.by_position.all
  end
end
