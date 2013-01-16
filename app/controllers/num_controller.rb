# -*- encoding : UTF-8 -*-
class NumController < ApplicationController
  layout "pages"

  before_filter :authenticate
  before_filter :load_resource, only: :index

  private

  def authenticate
    authenticate_or_request_with_http_basic do |name, password|
      [name, password].in? Num::USERS
    end
  end

  def load_resource
    @all_documents = Scan::Document.where(:updated_at.gte => Time.now.beginning_of_month)
    @groups = @all_documents.group_by { |e| e.updated_at.day }
    @day = params[:day].try(:to_i) || Time.now.day
    time = Time.local(Time.now.year,Time.now.month,@day)
    @documents = Scan::Document.where(:updated_at.gte => time, :updated_at.lte => time.end_of_day).desc(:updated_at)
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
      params[:scan_document][:name] << " all" unless params[:scan_document][:name].match(/ all$/)
      @document = Scan::Document.where(name: params[:scan_document][:name], :updated_at.gt => Time.now.beginning_of_month).first || Scan::Document.new
      @document.assign_attributes(params[:scan_document])
      if @document.persisted? && @document.valid?
        session[:document] = nil
        session[:old_document] = @document.reload
        session[:new_document] = {}
        session[:new_document][:name] = params[:scan_document][:name]
        session[:new_document][:paperclips] = params[:scan_document][:paperclips].to_i
        session[:new_document][:oversized] = params[:scan_document][:oversized].to_i
      else
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
    document.save
    flash[:success] = "Modifié avec succès."
    reset_waiting_document
    redirect_to "/num"
  end

  def overwrite
    document = Scan::Document.find params[:id]
    document.paperclips = params[:paperclips].to_i
    document.oversized = params[:oversized].to_i
    document.save
    reset_waiting_document
    flash[:success] = "Remplacé avec succès."
    redirect_to "/num"
  end

  def cancel
    reset_waiting_document
    redirect_to "/num"
  end
end
