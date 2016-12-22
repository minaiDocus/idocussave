# -*- encoding : UTF-8 -*-
class Account::ProviderWishesController < Account::FiduceoController
  before_filter :verify_rights
  before_filter :load_fiduceo_user_id

  # GET /account/provider_wishes
  def index
    @provider_wishes = FiduceoProviderWish.search_for_collection(@user.fiduceo_provider_wishes.not_processed_or_recent, search_terms(params[:provider_wish_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end


  # GET /account/provider_wishes/new
  def new
    @fiduceo_provider_wish = FiduceoProviderWish.new
  end


  # POST /account/provider_wishes
  def create
    @fiduceo_provider_wish = @user.fiduceo_provider_wishes.build fiduceo_provider_wish_params

    if @fiduceo_provider_wish.save
      flash[:success] = 'Votre demande est prise en compte. Nous vous apporterons une réponse dans les prochains jours.'

      redirect_to account_fiduceo_provider_wishes_path
    else
      render :new
    end
  end

  private

  def verify_rights
    unless @user.is_fiduceo_authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
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
end
