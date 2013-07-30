# -*- encoding : UTF-8 -*-
class Account::CollaboratorsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_collaborator, except: %w(index new create)

  def index
    @collaborators = search(user_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def show
  end

  def new
    @collaborator = User.new
  end

  def create
    @collaborator = User.new user_params
    @collaborator.is_prescriber = true
    @collaborator.set_random_password
    @collaborator.skip_confirmation!
    @collaborator.reset_password_token = User.reset_password_token
    @collaborator.reset_password_sent_at = Time.now
    if @collaborator.save
      @organization.members << @collaborator
      WelcomeMailer.welcome_collaborator(@collaborator).deliver
      flash[:notice] = 'Créé avec succès.'
      redirect_to account_organization_collaborator_path(@collaborator)
    else
      flash[:error] = 'Données invalide.'
      render action: 'new'
    end
  end

  def edit
  end

  def update
    attrs = @collaborator.request.attribute_changes.merge(user_params)
    if @collaborator.request.set_attributes(attrs, {}, @user)
      flash[:notice] = "En attente de validation de l'administrateur."
      redirect_to account_organization_collaborator_path(@collaborator)
    else
      render action: 'edit'
    end
  end

  def stop_using
    if @collaborator.request.set_attributes({ is_inactive: true }, {}, @user)
      flash[:notice] = 'Modifié avec succès'
    else
      flash[:notice] = "En attente de validation de l'administrateur."
    end
    redirect_to account_organization_collaborator_path(@collaborator)
  end

  def restart_using
    if @collaborator.request.set_attributes({ is_inactive: false }, {}, @user)
      flash[:notice] = 'Modifié avec succès'
    else
      flash[:notice] = "En attente de validation de l'administrateur."
    end
    redirect_to account_organization_collaborator_path(@collaborator)
  end

private

  def verify_rights
    unless is_leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def load_collaborator
    @collaborator = @organization.collaborators.find params[:id]
  end
  
  def user_params
    params.require(:user).permit(:code,
                                 :company,
                                 :first_name,
                                 :last_name,
                                 :email)
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

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
  helper_method :user_contains

  def search(contains)
    users = @organization.collaborators
    users = users.where(:first_name => /#{contains[:first_name]}/i) unless contains[:first_name].blank?
    users = users.where(:last_name  => /#{contains[:last_name]}/i)  unless contains[:last_name].blank?
    users = users.where(:email      => /#{contains[:email]}/i)      unless contains[:email].blank?
    users = users.where(:company    => /#{contains[:company]}/i)    unless contains[:company].blank?
    users = users.where(:code       => /#{contains[:code]}/i)       unless contains[:code].blank?
    users
  end
end