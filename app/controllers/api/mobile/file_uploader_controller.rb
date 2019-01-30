class Api::Mobile::FileUploaderController < MobileApiController
  include DocumentsHelper

  respond_to :json

  def load_file_upload_users
    render json: { userList: file_upload_users_list.map(&:code) }, status: 200
  end

  def load_file_upload_params
    render json: { data: file_upload_params_mobile }, status: 200
  end

  def load_user_analytics
    if(params[:user_id].present?)
      @customer = User.find params[:user_id]
    elsif params[:pieces].present?
      load_default_analytic_by_params params[:pieces], 'piece'
    end

    result = journal_analytic_references = pieces_analytic_references = {}

    if @customer && @customer.organization.ibiza.try(:configured?) && @customer.ibiza_id.present? && @customer.softwares.ibiza_compta_analysis_activated?
      load_default_analytic_by_params params[:journal], 'journal' if params[:journal].present?

      result = IbizaAnalytic.new(@customer.ibiza_id, @customer.organization.ibiza.access_token).list
      journal_analytic_references = @journal? JournalAnalyticReferences.new(@journal).get_analytic_references : {}
      pieces_analytic_references  = @pieces?  get_pieces_analytic_references : {}
    end

    defaults = pieces_analytic_references.presence || journal_analytic_references.presence || ''
    render json: { data: result.to_json.to_s, defaults: defaults.to_json.to_s  }, status: 200
  end

  def create
    data = nil

    if params[:file_code].present?
      customer = accounts.active.find_by_code(params[:file_code])
    else
      customer = @user
    end

    errors = []
    if customer.try(:options).try(:is_upload_authorized)
      params[:files].each do |file|
        uploaded_document = UploadedDocument.new(
          file.tempfile,
          file.original_filename,
          customer,
          params[:file_account_book_type],
          params[:file_prev_period_offset],
          @user,
          'mobile',
          parse_analytic_params
        )

        data = present(uploaded_document).to_json
        
        errors << { filename: file.original_filename, errors: uploaded_document.full_error_messages } unless uploaded_document.errors.empty?
      end
    else
      render json: { error: true, message: 'Accès non autorisé.' }, status: 401
      return
    end

    if errors.empty?
      render json: { success: true, message: 'Upload terminé avec succès.' }, status: 200
    else
      render json: { error: true, message: errors }, status: 200
    end
  end

  def set_pieces_analytics
    pieces    = Pack::Piece.where(id: params[:pieces].presence || 0).where("pre_assignment_state != 'ready'")

    messages = PiecesAnalyticReferences.new(pieces, parse_analytic_params).update_analytics

    render json: { success: true, error_message: messages[:error_message], sending_message: messages[:sending_message] }, status: 200
  end

  private

  def file_upload_params_mobile
    result = {}
    user = User.find params[:user_id]
    if user
      period_service = PeriodService.new user: user

      result = {
        journals: user.account_book_types.order(:name).map(&:info),
        periods:  options_for_period(period_service)
      }

      if period_service.prev_expires_at
        result[:message] = {
          period: period_option_label(period_service.period_duration, Time.now - period_service.period_duration.month),
          date:   l(period_service.prev_expires_at, format: '%d %B %Y à %H:%M')
        }
      end

      result[:compta_analysis] = user.uses_ibiza_analytics? ? true : false
    end
    result
  end

  def parse_analytic_params
    return nil unless params[:file_compta_analysis]

    begin
      analytic_parsed = JSON.parse(params[:file_compta_analysis])
    rescue
      analytic_parsed = params[:file_compta_analysis]
    end

    analysis = {}
    exist = false

    analytic_parsed.each_with_index do |a, l|
      i = l+1
      exist = true if a['analysis'].present?

      analysis["#{i.to_s}"] = { 'name' => a['analysis'].presence || '' }
      references = a['references']

      if references.any?
        references.each_with_index do |r, t|
          j = t+1
          analysis["#{i.to_s}#{j.to_s}"] =  {
                                              'ventilation' => r['ventilation'].presence || 0,
                                              'axis1'       => r['axis1'].presence || '',
                                              'axis2'       => r['axis2'].presence || '',
                                              'axis3'       => r['axis3'].presence || ''
                                            }
        end
      end
    end

    exist ? analysis.with_indifferent_access : nil
  end

  def load_default_analytic_by_params(param, type='journal')
    @journal  = (param.present? && type == 'journal') ? @customer.account_book_types.where(name: param).first : nil
    @pieces   = (param.present? && type == 'piece') ? Pack::Piece.where(id: param) : nil

    if @pieces
      @customer = @pieces.first.user
      journal_name = @pieces.collect(&:journal).uniq || []

      if journal_name.size == 1 && !@journal
        @journal  = @customer.account_book_types.where(name: journal_name.first).first || nil
      end
    end
  end

  def get_pieces_analytic_references
    analytic_refs = @pieces.collect(&:analytic_reference_id).compact
    analytic_refs.uniq!
    result = nil

    if analytic_refs.size == 1
      analytic = @pieces.first.analytic_reference || nil

      if analytic
        result =  {
                    a1_name:       analytic['a1_name'].presence,
                    a1_references: JSON.parse(analytic['a1_references']),
                    a2_name:       analytic['a2_name'].presence,
                    a2_references: JSON.parse(analytic['a2_references']),
                    a3_name:       analytic['a3_name'].presence,
                    a3_references: JSON.parse(analytic['a3_references']),
                  }.with_indifferent_access
      end
    end
    result
  end
end
