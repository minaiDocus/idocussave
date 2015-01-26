# -*- encoding : UTF-8 -*-
class Account::PackReportsController < Account::OrganizationController
  before_filter :load_report, except: :index

  def index
    @pack_reports = Pack::Report.preseizures.any_in(user_id: customer_ids)
    @pack_reports = @pack_reports.where(name: /#{Regexp.quote(params[:name])}/) if params[:name].present?
    if params[:view] == 'delivered'
      @pack_reports = @pack_reports.where(is_delivered: true)
    elsif params[:view] == 'not_delivered'
      @pack_reports = @pack_reports.where(is_delivered: false)
    end
    @pack_reports = @pack_reports.desc(:updated_at).limit(20).page(params[:page]).per(params[:per_page])
  end

  def deliver
    preseizures = @report.preseizures.by_position.not_locked.not_delivered.entries
    CreatePreAssignmentDeliveryService.new(preseizures).execute
    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end

  def select_to_download
  end

  def download
    preseizures = @report.preseizures.where(:_id.in => params[:download].try(:[], :preseizure_ids) || []).by_position
    case params[:download].try(:[], :format)
    when 'csv'
      if preseizures.any?
        send_data(@report.to_csv(@report.user.csv_outputter!, preseizures), type: 'text/csv', filename: "#{@report.name.gsub(' ','_')}.csv")
      else
        render action: 'select_to_download'
      end
    when 'xml'
      if current_user.is_admin
        if preseizures.any?
          file_name = "#{@report.name.gsub(' ','_')}.xml"
          ibiza = @organization.ibiza
          if ibiza && @report.user.ibiza_id
            date = DocumentTools.to_period(@report.name)
            if (exercice=ExerciceService.find(@report.user, date, false))
              data = IbizaAPI::Utils.to_import_xml(exercice, preseizures, ibiza.description, ibiza.description_separator, ibiza.piece_name_format, ibiza.piece_name_format_sep)
              send_data(data, type: 'application/xml', filename: file_name)
            else
              raise Mongoid::Errors::DocumentNotFound.new(Pack::Report, file_name)
            end
          else
            raise Mongoid::Errors::DocumentNotFound.new(Pack::Report, file_name)
          end
        else
          render action: 'select_to_download'
        end
      else
        raise Mongoid::Errors::DocumentNotFound.new(Pack::Report, file_name)
      end
    when 'zip'
      if @organization.is_quadratus_used
        file_path = QuadratusZipService.new(preseizures).execute
        send_file(file_path, type: 'application/zip', filename: File.basename(file_path), x_sendfile: true)
      else
        render action: 'select_to_download'
      end
    else
      render action: 'select_to_download'
    end
  end

private

  def load_report
    @report = Pack::Report.preseizures.any_in(user_id: customer_ids).where(_id: params[:id]).first
    raise Mongoid::Errors::DocumentNotFound.new(Pack::Report, params[:id]) unless @report
    @report
  end
end
