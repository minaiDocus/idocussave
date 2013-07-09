# -*- encoding : UTF-8 -*-
class NumController < ApplicationController
  layout "num"

  before_filter :authenticate
  before_filter :load_scanned_by
  before_filter :load_current_time
  before_filter :load_resource, only: :index

  private

  def authenticate
    unless current_user && current_user.is_admin
      authenticate_or_request_with_http_basic do |name, password|
        @user = Num::USERS.select { |u| u[0] == name && u[1] == password }.first
        @user.present?
      end
    end
  end

  def load_scanned_by
    @scanned_by = @user.try(:[], 2)
  end

  def load_current_time
    if params[:year] && params[:month] && params[:day]
      begin
        @current_time = "#{params[:year]}/#{params[:month]}/#{params[:day]}".to_time
      rescue ArgumentError
        @current_time = Time.now
      end
    else
      @current_time = Time.now
    end
  end

  def load_resource
    @all_documents = Scan::Document.where(:updated_at.gte => @current_time.beginning_of_month, :updated_at.lte => @current_time.end_of_month)
    @all_documents = @all_documents.where(scanned_by: /#{@scanned_by}/) if @scanned_by.present?
    @groups = @all_documents.group_by do |e|
      e.scanned_at.try(:day) || e.created_at.day
    end
    @day = @current_time.day
    time = @current_time.beginning_of_day
    @documents = Scan::Document.any_of({
                                          :scanned_at.gte => time,
                                          :scanned_at.lte => time.end_of_day
                                       },
                                       {
                                          scanned_at: nil,
                                          :created_at.gte => time,
                                          :created_at.lte => time.end_of_day
                                       }).
                                desc(:updated_at)
    @documents = @documents.where(scanned_by: /#{@scanned_by}/) if @scanned_by.present?
  end

  def reset_waiting_document
    session[:old_document] = nil
    session[:new_document] = nil
    session[:document] = nil
  end

  public

  def index
    @document = session[:document] || Scan::Document.new
  end

  def create
    if params[:scan_document] && params[:scan_document][:name] && params[:scan_document][:paperclips] && params[:scan_document][:oversized]
      params[:scan_document][:name].gsub!("_"," ")
      params[:scan_document][:name].strip!
      params[:scan_document][:name] << " all" unless params[:scan_document][:name].match(/ all$/)
      @document = Scan::Document.where(name: params[:scan_document][:name]).desc(:created_at).first
      if (@document.nil?) || (@document && @document.period && @document.period.end_at < Time.now)
        @document = Scan::Document.new
      end
      @document.assign_attributes(params[:scan_document])
      if @document.persisted? && @document.valid?
        session[:document] = nil
        session[:old_document] = @document.reload
        session[:new_document] = {}
        session[:new_document][:name] = params[:scan_document][:name]
        session[:new_document][:paperclips] = params[:scan_document][:paperclips].to_i
        session[:new_document][:oversized] = params[:scan_document][:oversized].to_i
      else
        @document.scanned_at = Time.now
        @document.scanned_by = @scanned_by
        if @document.save
          flash[:success] = "Créé avec succès."
          flash[:error] = nil
          session[:document] = nil
        else
          flash[:success] = nil
          flash[:error] = "Donnée(s) invalide(s)."
          session[:document] = @document
        end
      end
    end
    redirect_to "/num"
  end

  def add
    document = Scan::Document.find params[:id]
    document.paperclips += params[:paperclips].to_i
    document.oversized += params[:oversized].to_i
    document.updated_at = Time.now
    document.scanned_at = Time.now
    document.scanned_by = @scanned_by
    document.save
    flash[:success] = "Modifié avec succès."
    reset_waiting_document
    redirect_to "/num"
  end

  def overwrite
    document = Scan::Document.find params[:id]
    document.paperclips = params[:paperclips].to_i
    document.oversized = params[:oversized].to_i
    document.scanned_at = Time.now
    document.scanned_by = @scanned_by
    document.save
    reset_waiting_document
    flash[:success] = "Remplacé avec succès."
    redirect_to "/num"
  end

  def cancel
    reset_waiting_document
    redirect_to "/num"
  end

  def is_return_labels_authorized?
    (@user && @user[3]) or current_user
  end
  helper_method :is_return_labels_authorized?
end
