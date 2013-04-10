# -*- encoding : UTF-8 -*-
class Admin::OrganizationCsvOutputtersController < Admin::AdminController
  layout :nil_layout

  before_filter :load_organization
  before_filter :load_csv_outputter, except: :select_propagation_options

  def show
  end

  def select_propagation_options
    @customers = @organization.customers.active.asc(:code)
  end

  def propagate
    @csv_outputter.copy_to_users(params[:customers])
    flash[:notice] = 'Format de sortie CSV, propagé avec succès'
    redirect_to admin_organization_path(@organization)
  end

private

  def load_csv_outputter
    @csv_outputter = @organization.csv_outputter!
  end
end