# -*- encoding : UTF-8 -*-
class Admin::ReportingController < Admin::AdminController
  def index
    @year = params[:year].present? ? params[:year].to_i : Time.now.year
    @organizations = Organization.not_test.asc([:created_at, :name]).entries
    beginning_of_year = Time.local(@year, 1, 1)
    end_of_year = beginning_of_year.end_of_year
    @invoices = Invoice.any_in(organization_id: @organizations.map(&:_id)).
                        where(:created_at.gt => beginning_of_year + 1.month, :created_at.lt => end_of_year + 1.month).entries
  end
end