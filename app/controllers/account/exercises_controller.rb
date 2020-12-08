# frozen_string_literal: true

class Account::ExercisesController < Account::OrganizationController
  before_action :load_customer
  before_action :verify_rights
  before_action :verify_access
  before_action :redirect_to_current_step
  before_action :load_exercise, except: %w[index new create]

  # GET  /account/organizations/:organization_id/customers/:customer_id/exercises
  def index
    @exercises = @customer.exercises.order(start_date: :desc)
  end

  # GET /account/organizations/:organization_id/customers/:customer_id/exercises/new
  def new
    @exercise = Exercise.new
  end

  # POST /account/organizations/:organization_id/customers/:customer_id/exercises
  def create
    @exercise = Exercise.new exercise_params

    @exercise.user = @customer

    if @exercise.save
      flash[:success] = 'Créé avec succès.'

      redirect_to account_organization_customer_exercises_path(@organization, @customer)
    else
      render :new
    end
  end

  # GET /account/organizations/:organization_id/customers/:customer_id/exercises/edit
  def edit; end

  # PUT /account/organizations/:organization_id/customers/:customer_id/exercises/:id
  def update
    if @exercise.update(exercise_params)
      flash[:success] = 'Modifié avec succès.'

      redirect_to account_organization_customer_exercises_path(@organization, @customer)
    else
      render 'edit'
    end
  end

  # DELETE /account/organizations/:organization_id/customers/:customer_id/exercises/:id
  def destroy
    @exercise.destroy

    flash[:success] = 'Supprimé avec succès.'

    redirect_to account_organization_customer_exercises_path(@organization, @customer)
  end

  private

  def verify_rights
    unless @user.leader? || @user.manage_customers
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path(@organization)
    end
  end

  def verify_access
    if @customer.uses?(:ibiza)
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to account_organization_path(@organization)
    end
  end

  def load_customer
    @customer = customers.find params[:customer_id]
  end

  def load_exercise
    @exercise = @customer.exercises.find params[:id]
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
