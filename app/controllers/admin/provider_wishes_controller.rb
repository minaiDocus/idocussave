# -*- encoding : UTF-8 -*-
class Admin::ProviderWishesController < Admin::AdminController
  before_filter :load_provider_wish, except: :index

  def index
    @provider_wishes = search(provider_wish_contains).order([sort_column, sort_direction]).page(params[:page]).per(params[:per_page])
  end

  def edit
  end

  def start_process
    @provider_wish.start_process
    flash[:notice] = 'Statut changé avec succès.'
    redirect_to admin_fiduceo_provider_wishes_path
  end

  def reject
    if params[:fiduceo_provider_wish] && params[:fiduceo_provider_wish][:message].present?
      @provider_wish.update_attribute(:message, params[:fiduceo_provider_wish][:message])
    end
    @provider_wish.reject
    flash[:notice] = 'Statut changé avec succès.'
    redirect_to admin_fiduceo_provider_wishes_path
  end

  def accept
    @provider_wish.accept
    flash[:notice] = 'Statut changé avec succès.'
    redirect_to admin_fiduceo_provider_wishes_path
  end

private

  def load_provider_wish
    @provider_wish = FiduceoProviderWish.find params[:id]
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction

  def provider_wish_contains
    @contains ||= {}
    if params[:provider_wish_contains] && @contains.blank?
      @contains = params[:provider_wish_contains].delete_if do |_,value|
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
  helper_method :provider_wish_contains

  def search(contains)
    user_ids = []
    if params[:user_contains] && params[:user_contains][:code].present?
      user_ids = User.where(code: /#{Regexp.quote(params[:user_contains][:code])}/i).distinct(:_id)
    end
    provider_wishes = FiduceoProviderWish.all
    provider_wishes = provider_wishes.where(created_at:    contains[:created_at])                unless contains[:created_at].blank?
    provider_wishes = provider_wishes.where(updated_at:    contains[:updated_at])                unless contains[:updated_at].blank?
    provider_wishes = provider_wishes.any_in(user_id:      user_ids)                             if user_ids.any?
    provider_wishes = provider_wishes.where(state:         contains[:state])                     unless contains[:state].blank?
    provider_wishes = provider_wishes.where(name:          /#{Regexp.quote(contains[:name])}/i)  unless contains[:name].blank?
    provider_wishes = provider_wishes.where(url:           /#{Regexp.quote(contains[:url])}/i)   unless contains[:url].blank?
    provider_wishes = provider_wishes.where(login:         /#{Regexp.quote(contains[:login])}/i) unless contains[:login].blank?
    provider_wishes = provider_wishes.where(notified_at:   contains[:notified_at])               unless contains[:notified_at].blank?
    provider_wishes = provider_wishes.where(processing_at: contains[:processing_at])             unless contains[:processing_at].blank?
    if contains[:is_notified]
      if contains[:is_notified].to_i == 1
        provider_wishes = provider_wishes.notified
      elsif contains[:is_notified].to_i == 0
        provider_wishes = provider_wishes.not_notified
      end
    end
    provider_wishes
  end
end
