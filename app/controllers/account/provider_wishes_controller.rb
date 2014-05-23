# -*- encoding : UTF-8 -*-
class Account::ProviderWishesController < Account::FiduceoController
  layout 'layouts/account/retrievers'
  before_filter :verify_rights
  before_filter :load_fiduceo_user_id

  def index
    @provider_wishes = search(provider_wish_contains).order([sort_column, sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def new
    @fiduceo_provider_wish = FiduceoProviderWish.new
  end

  def create
    @fiduceo_provider_wish = @user.fiduceo_provider_wishes.build fiduceo_provider_wish_params
    if @fiduceo_provider_wish.save
      flash[:success] = 'Votre demande est prise en compte. Nous vous apporterons une réponse dans les prochains jours.'
      redirect_to account_fiduceo_provider_wishes_path
    else
      render action: 'new'
    end
  end

private

  def verify_rights
    unless @user.is_fiduceo_authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_documents_path
    end
  end

  def fiduceo_provider_wish_params
    params.require(:fiduceo_provider_wish).permit(:name, :url, :login, :password, :custom_connection_info, :description)
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def provider_wish_contains
    @contains ||= {}
    if params[:provider_wish_contains] && @contains.blank?
      @contains = params[:provider_wish_contains].delete_if do |_,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
    end
    @contains
  end
  helper_method :provider_wish_contains

  def search(contains)
    provider_wishes = @user.fiduceo_provider_wishes.not_processed_or_recent
    provider_wishes = provider_wishes.where(:name => /#{Regexp.quote(contains[:name])}/i) unless contains[:name].blank?
    provider_wishes
  end
end
