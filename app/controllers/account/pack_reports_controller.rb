# -*- encoding : UTF-8 -*-
class Account::PackReportsController < Account::OrganizationController
  def index
    @pack_reports = Pack::Report.preseizures.any_in(user_id: @user.customer_ids)
    if params[:name]
      pack_ids = @user.packs.where(name: /#{params[:name]}/).distinct(:_id)
      @pack_reports = @pack_reports.any_in(pack_id: pack_ids)
    end
    @pack_reports = @pack_reports.desc(:created_at).limit(20).page(params[:page]).per(params[:per_page])
  end

  def deliver
    pack_ids = @user.packs.distinct(:_id)
    if BSON::ObjectId.from_string(params[:id]).in?(pack_ids)
      if @user.organization.ibiza && @user.organization.ibiza.is_configured?
        @user.organization.ibiza.export(@pack.report.preseizures)
      end
    end
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end
end