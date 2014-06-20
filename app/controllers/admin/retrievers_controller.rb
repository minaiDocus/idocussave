# -*- encoding : UTF-8 -*-
class Admin::RetrieversController < Admin::AdminController
  def index
    @retrievers = search(retriever_contains).order([sort_column, sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def edit
  end

  def destroy
  end

private

  def load_retriever
    @retriever = FiduceoRetriever.find params[:id]
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def retriever_contains
    @contains ||= {}
    if params[:retriever_contains] && @contains.blank?
      @contains = params[:retriever_contains].delete_if do |_,value|
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
  helper_method :retriever_contains

  def search(contains)
    user_ids = []
    if params[:retriever_contains] && params[:retriever_contains][:user_code].present?
      user_ids = User.where(code: /#{Regexp.quote(params[:retriever_contains][:user_code])}/i).distinct(:_id)
    end
    retrievers = FiduceoRetriever.all
    retrievers = retrievers.where(created_at:   contains[:created_at])                       if contains[:created_at].present?
    retrievers = retrievers.where(updated_at:   contains[:updated_at])                       if contains[:updated_at].present?
    retrievers = retrievers.any_in(user_id:     user_ids)                                    if user_ids.any?
    retrievers = retrievers.where(state:        contains[:state])                            if contains[:state].present?
    retrievers = retrievers.where(type:         contains[:type])                             if contains[:type].present?
    retrievers = retrievers.where(service_name: /#{Regexp.quote(contains[:service_name])}/i) if contains[:service_name].present?
    retrievers = retrievers.where(name:         /#{Regexp.quote(contains[:name])}/i)         if contains[:name].present?
    retrievers
  end
end
