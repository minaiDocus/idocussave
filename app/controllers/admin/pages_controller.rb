# -*- encoding : UTF-8 -*-
class Admin::PagesController < Admin::AdminController
  helper_method :sort_column, :sort_direction, :page_contains

  def index
    @pages = Page.where(page_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end
  
  def show
    @page = Page.find_by_slug params[:id]
  end
  
  def new
    @page = Page.new
  end

  def create
    @page = Page.new params[:page]
    if @page.save
      flash[:notice] = "Crée avec succès."
      redirect_to admin_pages_path
    else
       flash[:error] = "Erreur lors de la création."
       render :action => "new"
     end
  end

  def edit
    @page = Page.find_by_slug params[:id]
  end
 
  def update
    @page = Page.find_by_slug params[:id]
      if @page.update_attributes(params[:page])
        flash[:notice] = "Modifié avec succès."
        redirect_to admin_pages_path
      else
        flash[:error] = "Impossible de modifier la page."
        render action: :edit
      end
  end

  private

  def sort_column
    params[:sort] || 'position'
  end

  def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def page_contains
    contains = {}
    if params[:page_contains]
      contains = params[:page_contains].delete_if do |key,value|
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
    contains
  end
    
end

