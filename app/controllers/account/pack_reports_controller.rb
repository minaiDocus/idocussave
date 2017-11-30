# -*- encoding : UTF-8 -*-
class Account::PackReportsController < Account::OrganizationController
  before_filter :load_report, except: :index

  # GET /account/organizations/:organization_id/pack_reports
  def index
    @pack_reports = Pack::Report.preseizures.where(user_id: customer_ids)
    @pack_reports = @pack_reports.where("name LIKE ?", "%#{params[:name]}%") if params[:name].present?

    if params[:view] == 'delivered'
      @pack_reports = @pack_reports.where(is_delivered: true)
    elsif params[:view] == 'not_delivered'
      @pack_reports = @pack_reports.where(is_delivered: false)
    end

    @pack_reports_count = @pack_reports.count

    @pack_reports = @pack_reports.order(updated_at: :desc).limit(20).page(params[:page]).per(params[:per_page])
  end


  # POST /account/organizations/:organization_id/pack_reports/deliver
  def deliver
    preseizures = @report.preseizures.by_position.not_locked.not_delivered

    CreatePreAssignmentDeliveryService.new(preseizures).execute

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
      if preseizures.any? && @report.organization.is_csv_descriptor_used
        data = PreseizuresToCsv.new(@report.user, preseizures).execute

        send_data(data, type: 'text/csv', filename: "#{@report.name.tr(' ', '_')}.csv")
      else
        unless @report.organization.is_csv_descriptor_used
          flash[:error] = "Veuillez activer l'export CSV dans les paramètres de l'organisation avant d'utiliser cette fonctionnalité."
        end
        render :select_to_download
      end
    when 'xml'
      if current_user.is_admin
        if preseizures.any?
          file_name = "#{@report.name.tr(' ', '_')}.xml"

          ibiza = @organization.ibiza

          if ibiza.try(:configured?) && @report.user.ibiza_id
            date = DocumentTools.to_period(@report.name)

            exercise = IbizaExerciseFinder.new(@report.user, date, ibiza).execute
            if exercise
              data = IbizaAPI::Utils.to_import_xml(exercise, preseizures, ibiza.description, ibiza.description_separator, ibiza.piece_name_format, ibiza.piece_name_format_sep)

              send_data(data, type: 'application/xml', filename: file_name)
            end
          end
        else
          render :select_to_download
        end
      end
    when 'zip'
      if @organization.is_quadratus_used
        file_path = QuadratusZipService.new(preseizures).execute

        logger.info(file_path.inspect)

        send_file(file_path, type: 'application/zip', filename: File.basename(file_path), x_sendfile: true)
      else
        render :select_to_download
      end
    when 'zip_coala'
      if @organization.is_coala_used
        file_path = CoalaZipService.new(@report.user, preseizures).execute
        send_file(file_path, type: 'application/zip', filename: File.basename(file_path), x_sendfile: true)
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
