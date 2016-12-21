# -*- encoding : UTF-8 -*-
class Admin::RetrieversController < Admin::AdminController
  def index
    @retrievers = search(retriever_contains).order_by(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def run
    retrievers = search(retriever_contains)
    count = retrievers.count
    retrievers.each(&:run)
    flash[:notice] = "#{count} récupération(s) en cours."
    redirect_to admin_retrievers_path(params.except(:authenticity_token))
  end

private

  def load_retriever
    @retriever = Retriever.find params[:id]
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
    retrievers = Retriever.all
    retrievers = retrievers.where(created_at:         contains[:created_at])                             if contains[:created_at].present?
    retrievers = retrievers.where(updated_at:         contains[:updated_at])                             if contains[:updated_at].present?
    retrievers = retrievers.any_in(user_id:           user_ids)                                          if user_ids.any?
    if contains[:capabilities].present? || contains[:service_name].present?
      connector_ids = []
      connectors = Connector.all
      if contains[:service_name].present?
        connectors = connectors.where(name: /#{Regexp.quote(contains[:service_name])}/i)
      end
      if contains[:capabilities].in? %w(bank document)
        connectors = connectors.where(capabilities: contains[:capabilities])
      elsif contains[:capabilities] == 'both'
        connectors = connectors.providers_and_banks
      end
      retrievers = retrievers.where(:connector_id.in => connectors.distinct(:_id))
    end
    retrievers = retrievers.where(name:               /#{Regexp.quote(contains[:name])}/i)               if contains[:name].present?
    retrievers = retrievers.where(state:              contains[:state])                                  if contains[:state].present?
    retrievers = retrievers.where(transaction_status: /#{Regexp.quote(contains[:transaction_status])}/i) if contains[:transaction_status].present?
    retrievers = retrievers.where(is_sane:            contains[:is_sane])                                if contains[:is_sane].present?
    retrievers.includes(:user, :journal, :connector)
  end
end
