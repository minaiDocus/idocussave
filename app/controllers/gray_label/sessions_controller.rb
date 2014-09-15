class GrayLabel::SessionsController < ApplicationController
  before_filter :load_session

  def create
    if @gray_label && @gray_label.is_active
      session[:gray_label_slug] = @gray_label.slug
    end
    redirect_to account_documents_path
  end

  def destroy
    if @gray_label && @gray_label.is_active && @gray_label.back_url.present?
      session[:gray_label_slug] = nil
      redirect_to @gray_label.back_url
    else
      redirect_to SITE_DEFAULT_URL
    end
  end

  private

  def load_session
    @gray_label = GrayLabel.find_by_slug params[:slug]
  end
end
