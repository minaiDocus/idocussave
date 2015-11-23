# -*- encoding : UTF-8 -*-
class Account::ExercisesController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :verify_access
  before_filter :load_customer
  before_filter :load_exercise, except: %w(index new create)

  def index
    @exercises = @customer.exercises.desc(:start_date)
  end

  def new
    @exercise = Exercise.new
  end

  def create
    @exercise = Exercise.new exercise_params
    @exercise.user = @customer
    if @exercise.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_customer_exercises_path(@organization, @customer)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @exercise.update(exercise_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_exercises_path(@organization, @customer)
    else
      render 'edit'
    end
  end

  def destroy
    @exercise.destroy
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_organization_customer_exercises_path(@organization, @customer)
  end

private

  def verify_rights
    unless is_leader? || @user.can_manage_customers?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def verify_access
    if @organization.ibiza.try(:access_token).present?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def load_customer
    @customer = customers.find_by_slug! params[:customer_id]
    raise Mongoid::Errors::DocumentNotFound.new(User, slug: params[:customer_id]) unless @customer
  end

  def load_exercise
    @exercise = @customer.exercises.find params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Exercise, nil, params[:id]) unless @exercise
  end

  def exercise_params
    params.require(:exercise).permit(:start_date,
                                     'start_date(3i)',
                                     'start_date(2i)',
                                     'start_date(1i)',
                                     :end_date,
                                     'end_date(3i)',
                                     'end_date(2i)',
                                     'end_date(1i)',
                                     :is_closed)
  end
end
