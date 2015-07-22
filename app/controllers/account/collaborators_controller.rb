# -*- encoding : UTF-8 -*-
class Account::CollaboratorsController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :load_collaborator, except: %w(index new create)

  def index
    @collaborators = search(user_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def show
  end

  def new
    @collaborator = User.new(code: "#{@organization.code}%")
  end

  def create
    @collaborator = User.new user_params
    @collaborator.organization = @organization
    @collaborator.is_prescriber = true
    @collaborator.set_random_password
    @collaborator.is_group_required = !(@user.my_organization || @user.is_admin)
    if @collaborator.save
      token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)
      @collaborator.reset_password_token = encrypted_token
      @collaborator.reset_password_sent_at = Time.now
      @collaborator.save
      WelcomeMailer.welcome_collaborator(@collaborator, token).deliver
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_collaborator_path(@organization, @collaborator)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    @collaborator.assign_attributes(user_params)
    is_email_changed = @collaborator.email_changed?
    if @collaborator.save
      if is_email_changed
        token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)
        @collaborator.reset_password_token = encrypted_token
        @collaborator.reset_password_sent_at = Time.now
        @collaborator.save
        WelcomeMailer.welcome_collaborator(@collaborator, token).deliver
      end
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_collaborator_path(@organization, @collaborator)
    else
      render action: 'edit'
    end
  end

  def destroy
    if DestroyCollaboratorService.new(@collaborator).execute
      flash[:success] = 'Supprimé avec succès.'
    else
      flash[:error] = 'Impossible de supprimer.'
    end
    redirect_to account_organization_collaborators_path(@organization)
  end

private

  def verify_rights
    unless is_leader? || @user.can_manage_collaborators?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_collaborator
    @collaborator = @organization.collaborators.find_by_slug! params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:id]) unless @collaborator
  end

  def user_params
    params.require(:user).permit(:code,
                                 { group_ids: [] },
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
    users = users.where(:first_name => /#{Regexp.quote(contains[:first_name])}/i) unless contains[:first_name].blank?
    users = users.where(:last_name  => /#{Regexp.quote(contains[:last_name])}/i)  unless contains[:last_name].blank?
    users = users.where(:email      => /#{Regexp.quote(contains[:email])}/i)      unless contains[:email].blank?
    users = users.where(:company    => /#{Regexp.quote(contains[:company])}/i)    unless contains[:company].blank?
    users = users.where(:code       => /#{Regexp.quote(contains[:code])}/i)       unless contains[:code].blank?
    users
  end
end
