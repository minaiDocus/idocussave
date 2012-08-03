# -*- encoding : UTF-8 -*-
class HomepageController < ApplicationController
  layout "pages"

  before_filter :authenticate_user!, only: :preview

  def index
    @homepage = Page.homepage
  end

  def preview
    if current_user.is_admin
      @homepage = Page.preview.find_by_slug(params[:id])
      if @homepage
        render action: :index
      else
        redirect_to root_path
      end
    else
      redirect_to root_path
    end
  end

end
