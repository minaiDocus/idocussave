# -*- encoding : UTF-8 -*-
class Admin::UsersController < Admin::AdminController
  helper_method :sort_column, :sort_direction, :user_contains

  def index
    @users = search(user_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def show
    @user = User.find params[:id]
    @user.request.apply_attribute_changes
  end

  def new
    @user = User.new
  end

  def create
    params[:user][:first_name] = params[:user][:first_name].upcase if params[:user][:first_name]
    params[:user][:last_name] = params[:user][:last_name].split.collect{|n| n.capitalize}.join(' ') if params[:user][:last_name]

    is_admin = params[:user][:is_admin].presence ? params[:user].delete(:is_admin) : false
    is_prescriber = params[:user][:is_prescriber].presence ? params[:user].delete(:is_prescriber) : false

    @user = User.new user_params
    @user.is_admin = is_admin
    @user.is_prescriber = is_prescriber
    AccountingPlan.create(user_id: @user.id)
    @user.skip_confirmation!
    if @user.save
      flash[:notice] = "Crée avec succès."
      redirect_to admin_users_path
    else
      flash[:error] = "Erreur lors de la création."
      render :action => "new"
    end
  end

  def update
    @user = User.find params[:id]
    respond_to do |format|
      if params[:user][:is_admin]
        @user.is_admin = params[:user].delete(:is_admin)
      end

      if params[:user][:is_prescriber]
        @user.is_prescriber = params[:user].delete(:is_prescriber)
      end

      if (params[:user].empty? && @user.save) || (params[:user].any? && @user.update_attributes(user_params))
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to admin_user_path(@user) }
      else
        format.json{ render json: @user.to_json, status: :unprocessable_entity }
        format.html{ redirect_to admin_user_path(@user), error: 'Impossible de modifier cette utilisateur.' }
      end
    end
  end

  def search_by_code
    tags = []
    full_info = params[:full_info].present?
    if params[:q].present?
      users = User.where(code: /.*#{params[:q]}.*/i).asc(:code).limit(10)
      users = users.prescribers if params[:prescriber].present?
      users.each do |user|
        tags << {id: user.id, name: full_info ? user.info : user.code}
      end
    end

    respond_to do |format|
      format.json{ render json: tags.to_json, status: :ok }
    end
  end

  def accept
    @user = User.find params[:id]
    if @user.request.accept!
      flash[:notice] = 'Modifié avec succès.'
    else
      flash[:error] = "Impossible de modifier."
    end
    redirect_to admin_user_path(@user)
  end

  def activate
    @user = User.find params[:id]
    if @user.activate!
      flash[:notice] = 'Activé avec succès.'
    else
      flash[:error] = "Impossible d'activer."
    end
    redirect_to admin_user_path(@user)
  end

  def destroy
    @user = User.find params[:id]
    if @user.request.status == 'create' && @user.destroy
      flash[:notice] = 'Supprimé avec succès.'
    else
      flash[:error] = 'Impossible de supprimer.'
    end
    redirect_to admin_users_path
  end
  
private

  def user_params
    params.require(:user).permit!
  end

  def sort_column
    params[:sort] || 'created_at'
  end

  def sort_direction
    params[:direction] || 'desc'
  end

  def user_contains
    @contains ||= {}
    if params[:user_contains] && @contains.blank?
      @contains = params[:user_contains].delete_if do |key,value|
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

  def search(contains)
    if contains[:request_action].present?
      user_ids = Request.where(requestable_type: 'User').any_of({ action: contains[:request_action] }, { relation_action: contains[:request_action] }).distinct(:requestable_id)
      user_ids = user_ids + Scan::Subscription.where(request_action: contains[:request_action]).distinct(:user_id)
      users = User.any_in(:_id => user_ids)
    else
      users = User.all
    end
    users = users.where(:first_name => /#{contains[:first_name]}/i) unless contains[:first_name].blank?
    users = users.where(:last_name => /#{contains[:last_name]}/i) unless contains[:last_name].blank?
    users = users.where(:email => /#{contains[:email]}/i) unless contains[:email].blank?
    users = users.where(:company => /#{contains[:company]}/i) unless contains[:company].blank?
    users = users.where(:code => /#{contains[:code]}/i) unless contains[:code].blank?
    users = users.where(:request_type => contains[:request_type]) unless contains[:request_type].blank?
    users = users.where(:organization_id => contains[:organization_id]) unless contains[:organization_id].blank?
    users
  end
end
