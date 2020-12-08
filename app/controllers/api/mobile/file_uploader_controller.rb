# frozen_string_literal: true

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
    if params[:user_id].present?
      @customer = User.find params[:user_id]
    elsif params[:pieces].present?
      load_default_analytic_by_params params[:pieces], 'piece'
    end

    result = journal_analytic_references = pieces_analytic_references = {}

    if @customer && @customer.organization.ibiza.try(:configured?) && @customer.try(:ibiza).try(:ibiza_id?) && @customer.try(:ibiza).try(:compta_analysis_activated?)
      if params[:journal].present?
        load_default_analytic_by_params params[:journal], 'journal'
      end

      result = IbizaLib::Analytic.new(@customer.try(:ibiza).try(:ibiza_id), @customer.organization.ibiza.access_token, @customer.organization.ibiza.specific_url_options).list
      journal_analytic_references = @journal ? Journal::AnalyticReferences.new(@journal).get_analytic_references : {}
      pieces_analytic_references  = @pieces ? get_pieces_analytic_references : {}
    end

    defaults = pieces_analytic_references.presence || journal_analytic_references.presence || ''
    render json: { data: result.to_json.to_s, defaults: defaults.to_json.to_s }, status: 200
  end

  def create
    data = nil

    customer = if params[:file_code].present?
                 accounts.active.find_by_code(params[:file_code])
               else
                 @user
               end

    @uploaded_files = params[:files]
    @errors = []

    if customer.try(:options).try(:is_upload_authorized)
      CustomUtils.mktmpdir('file_uploader_controller') do |dir|
        @dir = dir

        final_file_name = "composed_mobile_img_#{Time.now.strftime('%Y%m%d%H%M%S')}.pdf"
        @final_file_path = File.join(@dir, final_file_name)

        @uploaded_files.each do |p_file|
          merge_img_file p_file.tempfile, p_file.original_filename
        end

        if File.exist? @final_file_path
          final_file = File.open(@final_file_path, 'r')

          uploaded_document = UploadedDocument.new(
            final_file,
            final_file_name,
            customer,
            params[:file_account_book_type],
            params[:file_prev_period_offset],
            @user,
            'mobile',
            parse_analytic_params
          )

          data = present(uploaded_document).to_json

          if uploaded_document.errors.any?
            set_errors_to_files(uploaded_document.full_error_messages)
          end
        else
          set_errors_to_files("Une erreur inatendue s'est produite, veuillez relancer l'upload svp")
        end
      end
    else
      render json: { error: true, message: 'Accès non autorisé.' }, status: 401
      return
    end

    if @errors.empty?
      render json: { success: true, message: 'Upload terminé avec succès.' }, status: 200
    else
      render json: { error: true, message: @errors }, status: 200
    end
  end

  def set_pieces_analytics
    pieces = Pack::Piece.where(id: params[:pieces].presence || 0).where("pre_assignment_state != 'ready'")

    messages = PiecesAnalyticReferences.new(pieces, parse_analytic_params).update_analytics

    render json: { success: true, error_message: messages[:error_message], sending_message: messages[:sending_message] }, status: 200
  end

  private

  def file_upload_params_mobile
    result = {}
    user = User.find params[:user_id]
    if user
      period_service = Billing::Period.new user: user

      result = {
        journals: user.account_book_types.order(:name).map(&:info),
        periods: options_for_period(period_service)
      }

      if period_service.prev_expires_at
        result[:message] = {
          period: period_option_label(period_service.period_duration, Time.now - period_service.period_duration.month),
          date: l(period_service.prev_expires_at, format: '%d %B %Y à %H:%M')
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
    rescue StandardError
      analytic_parsed = params[:file_compta_analysis]
    end

    analysis = {}
    exist = false

    analytic_parsed.each_with_index do |a, l|
      i = l + 1
      exist = true if a['analysis'].present?

      analysis[i.to_s] = { 'name' => a['analysis'].presence || '' }
      references = a['references']

      next unless references.any?

      references.each_with_index do |r, t|
        j = t + 1
        analysis["#{i}#{j}"] = {
          'ventilation' => r['ventilation'].presence || 0,
          'axis1' => r['axis1'].presence || '',
          'axis2' => r['axis2'].presence || '',
          'axis3' => r['axis3'].presence || ''
        }
      end
    end

    exist ? analysis.with_indifferent_access : nil
  end

  def load_default_analytic_by_params(param, type = 'journal')
    @journal  = param.present? && type == 'journal' ? @customer.account_book_types.where(name: param).first : nil
    @pieces   = param.present? && type == 'piece' ? Pack::Piece.where(id: param) : nil

    if @pieces
      @customer = @pieces.first.user
      journal_name = @pieces.collect(&:journal).uniq || []

      if journal_name.size == 1 && !@journal
        @journal = @customer.account_book_types.where(name: journal_name.first).first || nil
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
        result = {
          a1_name: analytic['a1_name'].presence,
          a1_references: JSON.parse(analytic['a1_references']),
          a2_name: analytic['a2_name'].presence,
          a2_references: JSON.parse(analytic['a2_references']),
          a3_name: analytic['a3_name'].presence,
          a3_references: JSON.parse(analytic['a3_references'])
        }.with_indifferent_access
      end
    end
    result
  end

  def merge_img_file(file, original_filename)
    create_pdf_file_from file, original_filename
    append_img_pdf_to_final_file
  end

  def create_pdf_file_from(file, original_filename)
    @img_file_path = File.join(@dir, 'tmp_img.pdf')

    DocumentTools.to_pdf(file.path, @img_file_path, @dir)

    unless File.exist? @img_file_path
      @errors << { filename: original_filename, errors: 'Image non supportée' }
    end
  end

  def append_img_pdf_to_final_file
    return false unless File.exist? @img_file_path

    if File.exist? @final_file_path
      merged_file_path = File.join(@dir, 'tmp_merge.pdf')
      Pdftk.new.merge([@final_file_path, @img_file_path], merged_file_path)

      FileUtils.rm @final_file_path
      FileUtils.mv merged_file_path, @final_file_path
    else
      FileUtils.copy @img_file_path, @final_file_path
    end

    FileUtils.rm @img_file_path
  end

  def set_errors_to_files(message)
    @errors = [] # reset @errors

    @uploaded_files.each do |file|
      @errors << { filename: file.original_filename, errors: message }
    end
  end
end
