class Admin::Log::VisitsController < Admin::AdminController
  helper_method :sort_column, :sort_direction, :visit_contains
  
  def index
    @visits = ::Log::Visit.where(visit_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def show
  end
  
  def visit_contains
    contains = {}
    if params[:visit_contains]
      contains = params[:visit_contains].delete_if do |key,value|
        if value.blank? && !value.is_a?(Hash)
          true
        elsif value.is_a? Hash
          value.delete_if { |k,v| v.blank? }
          value.blank?
        else
          false
        end
      end
      if params[:user]
        user = User.where(params[:user]).first
        contains.merge!({ user_id: user.id }) if user
      else
        contains.merge!({ user_id: nil })
      end
    end
    contains
  end
  
  def sort_column
    params[:sort] || 'number'
  end
  
  def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : 'desc'
  end
  
end
