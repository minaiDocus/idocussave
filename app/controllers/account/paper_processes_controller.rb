# -*- encoding : UTF-8 -*-
class Account::PaperProcessesController < Account::AccountController
  def index
    @paper_processes = search(paper_process_contains).order([sort_column, sort_direction]).page(params[:page]).per(params[:per_page])
  end

private

  def sort_column
    params[:sort] || 'updated_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def paper_process_contains
    @contains ||= {}
    if params[:paper_process_contains] && @contains.blank?
      @contains = params[:paper_process_contains].delete_if do |_,value|
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
  helper_method :paper_process_contains

  def search(contains)
    if @user.is_prescriber && @user.organization
      paper_processes = PaperProcess.where(:user_id.in => @user.customers.map(&:id)).includes(:user)
    else
      paper_processes = @user.paper_processes
    end
    paper_processes = paper_processes.where(updated_at:      contains[:updated_at])                          if contains[:updated_at]
    paper_processes = paper_processes.where(type:            Regexp.quote(contains[:type]))                  if contains[:type]
    paper_processes = paper_processes.where(customer_code:   /#{Regexp.quote(contains[:customer_code])}/i)   if contains[:customer_code]
    if contains[:customer_company].present?
      user_ids = @user.customers.where(company: /#{Regexp.quote(contains[:customer_company])}/i).distinct(:_id)
      paper_processes = paper_processes.where(:user_id.in => user_ids)
    end
    paper_processes = paper_processes.where(tracking_number: /#{Regexp.quote(contains[:tracking_number])}/i) if contains[:tracking_number]
    paper_processes = paper_processes.where(pack_name:       /#{Regexp.quote(contains[:pack_name])}/i)       if contains[:pack_name]
    paper_processes
  end
end
