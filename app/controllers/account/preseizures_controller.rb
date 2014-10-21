# -*- encoding : UTF-8 -*-
class Account::PreseizuresController < Account::OrganizationController
  before_filter :preseizure_params, only: :update
  before_filter :load_preseizure, except: :index

  def index
    if params[:name].present?
      report = Pack::Report.preseizures.any_in(user_id: customer_ids).where(name: /#{params[:name].gsub('_',' ')}/).first
      if report
        @preseizures = report.preseizures.by_position.page(params[:page]).per(params[:per_page])
      else
        @preseizures = []
      end
    else
      redirect_to root_path
    end
  end

  def show
    if params[:format] == 'xml'
      if current_user.is_admin
        report = @preseizure.report
        position = "%0#{DocumentProcessor::POSITION_SIZE}d" % @preseizure.position
        file_name = "#{report.name.sub(' ','_')}_#{position}.xml"
        ibiza = @organization.ibiza
        if ibiza && report.user.ibiza_id
          date = DocumentTools.to_period(report.name)
          if (exercice=ExerciceService.find(report.user, date, false))
            data = IbizaAPI::Utils.to_import_xml(exercice, [@preseizure], ibiza.description, ibiza.description_separator, ibiza.piece_name_format, ibiza.piece_name_format_sep)
          else
            raise Mongoid::Errors::DocumentNotFound.new(Pack::Report::Preseizure, file_name)
          end
        else
          raise Mongoid::Errors::DocumentNotFound.new(Pack::Report::Preseizure, file_name)
        end
      else
        raise Mongoid::Errors::DocumentNotFound.new(Pack::Report::Preseizure, file_name)
      end
    end
    respond_to do |format|
      format.html do
        raise Mongoid::Errors::DocumentNotFound.new(Pack::Report::Preseizure, params[:id])
      end
      format.xml do
        send_data(data, type: 'application/xml', filename: file_name)
      end
    end
  end

  def update
    @preseizure.update_attributes(preseizure_params)
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

  def deliver
    CreatePreAssignmentDeliveryService.new(@preseizure).execute
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

private

  def load_preseizure
    @preseizure = Pack::Report::Preseizure.find params[:id]
    raise Mongoid::Errors::DocumentNotFound.new(Pack::Report::Preseizure, params[:id]) unless @preseizure.report.user.in? customers
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
