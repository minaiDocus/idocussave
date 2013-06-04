# -*- encoding : UTF-8 -*-
class Account::PreseizuresController < Account::OrganizationController
  before_filter :preseizure_params, only: :update
  before_filter :load_preseizure, except: :index

  def index
    @pack = @user.packs.where(:name => /#{params[:name].gsub('_',' ')}/).first
    if @pack && @pack.report
      @preseizures = @pack.report.preseizures.page(params[:page]).per(params[:per_page])
    else
      @preseizures = []
    end
  end

  def update
    @preseizure.update_attributes(preseizure_params)
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

  def deliver
    if @user.organization.ibiza && @user.organization.ibiza.is_configured?
      @user.organization.ibiza.export([@preseizure])
    end
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

private

  def load_preseizure
    @preseizure = Pack::Report::Preseizure.find params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Pack::Report::Preseizure, params[:id]) unless @user.packs.include? @preseizure.report.pack
  end

  def preseizure_params
    params.require(:preseizure).permit(:position,
                                       :date,
                                       :third_party,
                                       :piece_number,
                                       :amount,
                                       :currency,
                                       :convertion_rate,
                                       :deadline_date,
                                       :observation)
  end
end