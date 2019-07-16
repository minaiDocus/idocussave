# -*- encoding : UTF-8 -*-
class Account::PackReportsController < Account::OrganizationController
  before_filter :load_report, except: :index

  # GET /account/organizations/:organization_id/pack_reports
  def index
    @pack_reports = Pack::Report.preseizures.joins(:preseizures).where(user_id: customer_ids).uniq

    if params[:filter].present?
      tmp_reports = @pack_reports.where('pack_reports.name LIKE ?', "%#{params[:filter].gsub('+', ' ')}%")
      if tmp_reports.count == 0
        preseizures = Pack::Report::Preseizure.where(report_id: @pack_reports.pluck(:id).presence || [0])
        preseizures = preseizures.where('pack_report_preseizures.third_party LIKE ?', "%#{params[:filter].gsub('+', ' ')}%")

        @pack_reports = @pack_reports.where(id: preseizures.pluck(:report_id).presence || [0]) unless params[:view] == 'delivered' || params[:view] == 'not_delivered'
      else
        @pack_reports = @pack_reports.where('pack_reports.name LIKE ?', "%#{params[:filter].gsub('+', ' ')}%")
        preseizures = Pack::Report::Preseizure.where(report_id: @pack_reports.pluck(:id).presence || [0])
      end
    else
      preseizures = Pack::Report::Preseizure.where(report_id: @pack_reports.pluck(:id).presence || [0])
    end

    if params[:view] == 'delivered'
      @pack_reports = @pack_reports.where(id: preseizures.delivered.distinct.pluck(:report_id).presence || [0])
    elsif params[:view] == 'not_delivered'
      @pack_reports = @pack_reports.where(id: preseizures.not_delivered.distinct.pluck(:report_id).presence || [0])
    end

    @pack_reports = @pack_reports.order(updated_at: :desc).page(params[:page]).per(params[:per_page])

    @pack_reports_count = @pack_reports.total_count
  end


  # POST /account/organizations/:organization_id/pack_reports/deliver
  def deliver
    preseizures = @report.preseizures.by_position.not_locked.not_delivered

    CreatePreAssignmentDeliveryService.new(preseizures, ['ibiza', 'exact_online']).execute

    respond_to do |format|
      format.json { render json: { status: :ok } }
    end
  end


  # GET /account/organizations/:organization_id/pack_reports/select_to_download
  def select_to_download
  end


  # POST /account/organizations/:organization_id/pack_reports/:id/download
  def download
    preseizures = @report.preseizures.where(id: params[:download].try(:[], :preseizure_ids) || []).by_position

    case params[:download].try(:[], :format)
    when 'csv'
      if preseizures.any? && @report.user.uses_csv_descriptor?
        data = PreseizuresToCsv.new(@report.user, preseizures).execute

        send_data(data, type: 'text/csv', filename: "#{@report.name.tr(' ', '_').tr('%', '_')}.csv", x_sendfile: true, :disposition => 'inline')
      else
        unless @report.user.uses_csv_descriptor?
          flash[:error] = "Veuillez activer l'export CSV dans les paramètres de l'organisation et paramètres client avant d'utiliser cette fonctionnalité."
        end
        render :select_to_download
      end
    when 'xml_ibiza'
      if current_user.is_admin
        if preseizures.any?
          file_name = "#{@report.name.tr(' ', '_').tr('%', '_')}.xml"

          ibiza = @organization.ibiza

          if ibiza.try(:configured?) && @report.user.ibiza_id && @report.user.uses_ibiza?
            date = DocumentTools.to_period(@report.name)

            exercise = IbizaExerciseFinder.new(@report.user, date, ibiza).execute
            if exercise
              data = IbizaAPI::Utils.to_import_xml(exercise, preseizures, ibiza)

              send_data(data, type: 'application/xml', filename: file_name, x_sendfile: true, :disposition => 'inline')
            else
              render :select_to_download
            end
          else
            render :select_to_download
          end
        else
          render :select_to_download
        end
      end
    when 'zip_quadratus'
      if @report.user.uses_quadratus?
        file_path = QuadratusZipService.new(preseizures).execute

        logger.info(file_path.inspect)

        send_file(file_path, type: 'application/zip', filename: File.basename(file_path), x_sendfile: true)
      else
        render :select_to_download
      end
    when 'zip_coala'
      if @report.user.uses_coala?
        file_path = CoalaZipService.new(@report.user, preseizures, {to_xls: true}).execute
        send_file(file_path, type: 'application/zip', filename: File.basename(file_path), x_sendfile: true)
      else
        render action: 'select_to_download'
      end
    when 'xls_coala'
      if @organization.is_coala_used
        file_path = CoalaZipService.new(@report.user, preseizures, {preseizures_only: true, to_xls: true}).execute
        send_file(file_path, type: 'text/xls', filename: File.basename(file_path), x_sendfile: true)
      else
        render action: 'select_to_download'
      end
    else
      render :select_to_download
    end
  end

  private

  def load_report
    @report = Pack::Report.preseizures.where(user_id: customer_ids, id: params[:id]).first
    raise ActiveRecord::RecordNotFound unless @report
  end
end