# frozen_string_literal: true

class Admin::ProcessReportingController < Admin::AdminController
  # GET /admin/process_reporting
  def index
    year  = params[:year].present?  ? params[:year].to_i  : Time.now.year
    month = params[:month].present? ? params[:month].to_i : Time.now.month

    begin
      @time = Time.local(year, month)
    rescue
      @time = Time.local(Time.now.year, Time.now.month)
    end

    @organizations = Organization.includes(:customers).order(name: :asc)
  end

  def process_reporting_table
    year  = params[:year].present?  ? params[:year].to_i  : Time.now.year
    month = params[:month].present? ? params[:month].to_i : Time.now.month

    begin
      @time = Time.local(year, month)
    rescue
      @time = Time.local(Time.now.year, Time.now.month)
    end

    @organization = Organization.find(params[:organization_id])

    render partial: 'process_reporting_table'
  end
end
