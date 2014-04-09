# -*- encoding : UTF-8 -*-
class Admin::DematboxFilesController < Admin::AdminController
  helper_method :sort_column, :sort_direction, :page_contains

  def index
    @dematbox_files = TempDocument.dematbox_scan.originals.where(dematbox_file_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end

private
  
  def sort_column
    params[:sort] || 'created_at'
  end

  def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : 'desc'
  end

  def dematbox_file_contains
    contains = {}
    if params[:dematbox_file_contains]
      contains = params[:dematbox_file_contains].delete_if do |key,value|
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
    if contains['created_at']
      contains['created_at']['$gte'] = contains['created_at']['$gte'].try(:to_time)
      contains['created_at']['$lte'] = contains['created_at']['$lte'].try(:to_time).try(:end_of_day)
    end
    if contains['dematbox_is_notified']
      contains['dematbox_is_notified'] = contains['dematbox_is_notified'].to_i == 1 ? true : nil
    end
    contains
  end
end
