# -*- encoding : UTF-8 -*-
class Account::IbizaController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_ibiza, except: :create


  # POST /account/organizations/:organization_id/ibiza
  def create
    @ibiza = Ibiza.new(ibiza_params)
    @ibiza.organization = @organization

    if @ibiza.save
      if @ibiza.need_to_verify_access_tokens?
        VerifyIbizaAccessTokens.new(@ibiza.id.to_s).execute
      end

      flash[:success] = 'Créé avec succès.'

      redirect_to account_organization_path(@organization, tab: 'ibiza')
    else
      render :edit
    end
  end


  # GET /account/organizations/:organization_id/ibiza/edit
  def edit
  end


  # PUT /account/organizations/:organization_id/ibiza
  def update
    if @ibiza.update(ibiza_params)
      if @ibiza.need_to_verify_access_tokens?
        VerifyIbizaAccessTokens.new(@ibiza.id.to_s).execute
      end

      flash[:success] = 'Modifié avec succès.'

      redirect_to account_organization_path(@organization, tab: 'ibiza')
    else
      render :edit
    end
  end

  private

  def verify_rights
    unless @user.leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end


  def load_ibiza
    @ibiza = @organization.ibiza
  end


  def ibiza_params
    params.require(:ibiza).permit(:access_token, :access_token_2, :is_auto_deliver, :is_analysis_activated, :is_analysis_to_validate, :description_separator, :piece_name_format_sep, :voucher_ref_target).tap do |whitelist|
      whitelist[:description]       = params[:ibiza][:description].permit!
      whitelist[:piece_name_format] = params[:ibiza][:piece_name_format].permit!
    end
  end
end
