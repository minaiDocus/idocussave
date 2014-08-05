# -*- encoding : UTF-8 -*-
class Account::ExercicesController < Account::OrganizationController
  before_filter :verify_rights
  before_filter :verify_access
  before_filter :load_customer
  before_filter :load_exercice, except: %w(index new create)

  def index
    @exercices = @customer.exercices.desc(:start_date)
  end

  def new
    @exercice = Exercice.new
  end

  def create
    @exercice = Exercice.new exercice_params
    @exercice.user = @customer
    if @exercice.save
      flash[:success] = 'Créé avec succès.'
      redirect_to account_organization_customer_exercices_path(@customer)
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @exercice.update_attributes(exercice_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_customer_exercices_path(@customer)
    else
      render 'edit'
    end
  end

  def destroy
    @exercice.destroy
    flash[:success] = 'Supprimé avec succès.'
    redirect_to account_organization_customer_exercices_path(@customer)
  end

private

  def verify_rights
    unless is_leader? || @user.can_manage_customers?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def verify_access
    if @organization.ibiza.try(:token).present?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path
    end
  end

  def load_customer
    @customer = customers.find params[:customer_id]
  end

  def load_exercice
    @exercice = @customer.exercices.find params[:id]
  end

  def exercice_params
    params.require(:exercice).permit(:start_date,
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
