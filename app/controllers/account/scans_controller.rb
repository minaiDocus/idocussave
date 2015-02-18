# -*- encoding : UTF-8 -*-
class Account::ScansController < Account::AccountController
  def index
    @scans = search(scan_contains).order([sort_column, sort_direction]).page(params[:page]).per(params[:per_page])
  end

private

  def sort_column
    params[:sort] || 'scanned_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def scan_contains
    @contains ||= {}
    if params[:scan_contains] && @contains.blank?
      @contains = params[:scan_contains].delete_if do |_,value|
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
  helper_method :scan_contains

  def search(contains)
    if @user.is_prescriber && @user.organization
      scans = Scan::Document.scanned.where(:user_id.in => @user.customers.map(&:id))
    else
      scans = @user.period_documents.scanned
    end
    scans = scans.includes(:pack)
    scans = scans.where(scanned_at: contains[:scanned_at])                if contains[:scanned_at]
    scans = scans.where(name:       /#{Regexp.quote(contains[:name])}/i) if contains[:name]
    scans
  end
end
