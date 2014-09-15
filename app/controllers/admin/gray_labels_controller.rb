# -*- encoding : UTF-8 -*-
class Admin::GrayLabelsController < Admin::AdminController
  before_filter :load_gray_label, except: %w(index new create)

  def index
    @gray_labels = GrayLabel.where(gray_label_contains).order([sort_column,sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def show
  end

  def new
    @gray_label = GrayLabel.new
  end

  def create
    @gray_label = GrayLabel.new params[:gray_label]
    if @gray_label.save
      flash[:notice] = 'Créé avec succès.'
      redirect_to admin_gray_label_path(@gray_label)
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @gray_label.update_attributes(params[:gray_label])
      flash[:notice] = 'Modifié avec succès.'
      redirect_to admin_gray_label_path(@gray_label)
    else
      render 'edit'
    end
  end

  def destroy
    @gray_label.destroy
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_gray_labels_path
  end

private

  def load_gray_label
    @gray_label = GrayLabel.find_by_slug params[:id]
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : 'asc'
  end
  helper_method :sort_direction

  def gray_label_contains
    contains = {}
    if params[:gray_label_contains]
      contains = params[:gray_label_contains].delete_if do |key,value|
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
  helper_method :gray_label_contains
end
