# frozen_string_literal: true

class Account::DocumentsController < Account::AccountController
  layout :current_layout

  skip_before_action :login_user!, only: %w[download piece handle_bad_url temp_document get_tag]

  # GET /account/documents
  def index
    options = {
      owner_ids: account_ids,
      page: params[:page],
      per_page: params[:per_page],
      sort: true
    }

    pack_with_includes = Pack.includes(:owner, :preseizures, :cloud_content_attachment, :reports)

    if params[:pack_name].present?
      @packs = pack_with_includes.where(owner_id: options[:owner_ids], name: params[:pack_name]).page(options[:page]).per(options[:per_page])
      @reports = Pack::Report.where(user_id: options[:owner_ids], name: params[:pack_name].gsub('all', '').strip, pack_id: nil).order(updated_at: :desc).page(options[:page]).per(options[:per_page])
    else
      @packs   = pack_with_includes.search(params.try(:[], :by_piece).try(:[], :content), options)
      @reports = Pack::Report.where(user_id: options[:owner_ids], pack_id: nil).order(updated_at: :desc).page(options[:page]).per(options[:per_page])
    end

    @last_composition = @user.composition

    ### TODO : GET DOCUMENTS COMPOSITION FROM PIECES INSTEAD OF DOCUMENTS FOR COMPOSITION CREATED AFTER 23/01/2019
    @composition = nil # TEMP FIX
    # @composition      = Document.where(id: @last_composition.document_ids) if @last_composition
    ######################

    @period_service = Billing::Period.new user: @user
  end

  # GET /account/documents/:id
  def show
    @data_type = params[:fetch] || 'pieces'
    @data_source = params[:source] || 'pack'

    if @data_type == 'pieces' && @data_source == 'pack'
      show_pack_pieces
    else
      show_report_preseizures
    end
  end

  # GET /account/documents/packs
  def packs
    if params[:view] == 'current_delivery'
      pack_ids = @user.remote_files.not_processed.distinct.pluck(:pack_id)
      @packs = Pack.where(owner_id: account_ids, id: pack_ids)
                   .order(updated_at: :desc)
                   .page(params[:page])
                   .per(params[:per_page])
      @remaining_files = @user.remote_files.not_processed.count
    else
      if params[:by_all].present?
        params[:by_piece] = params[:by_piece].present? ? params[:by_piece].merge(params[:by_all].permit!) : params[:by_all]
      end

      options = { page: params[:page], per_page: params[:per_page] }
      options[:sort] = true

      options[:piece_created_at] = params[:by_piece].try(:[], :created_at)
      options[:piece_created_at_operation] = params[:by_piece].try(:[], :created_at_operation)

      options[:piece_position] = params[:by_piece].try(:[], :position)
      options[:piece_position_operation] = params[:by_piece].try(:[], :position_operation)

      options[:name] = params[:by_pack].try(:[], :pack_name)
      options[:tags] = params[:by_piece].try(:[], :tags)

      options[:pre_assignment_state] = params[:by_piece].try(:[], :state_piece)

      options[:owner_ids] = if params[:view].present? && params[:view] != 'all'
                              _user = accounts.find(params[:view])
                              _user ? [_user.id] : []
                            else
                              account_ids
      end

      if params[:by_preseizure].present?
        piece_ids = Pack::Report::Preseizure.where(user_id: options[:owner_ids], operation_id: ['', nil]).filter_by(params[:by_preseizure]).distinct.pluck(:piece_id).presence || [0]
      end

      options[:piece_ids] = piece_ids if piece_ids.present?

      @packs = Pack.search(params.try(:[], :by_piece).try(:[], :content), options).distinct.order(updated_at: :desc).page(options[:page]).per(options[:per_page])

    end
  end

  def reports
    if params[:view] == 'current_delivery'
      # send empty ActiveRelation
      @reports = Pack::Report.where(id: 0).page(params[:page] || 1).per(params[:per_page] || 20)
    else
      options = {}

      options[:user_ids] = if params[:view].present? && params[:view] != 'all'
                             _user = accounts.find(params[:view])
                             _user ? [_user.id] : []
                           else
                             account_ids
      end

      if params[:by_all].present?
        params[:by_preseizure] = params[:by_preseizure].present? ? params[:by_preseizure].merge(params[:by_all].permit!) : params[:by_all]
      end

      options[:name] = params[:by_pack].try(:[], :pack_name)

      if params[:by_preseizure].present?
        reports_ids = Pack::Report::Preseizure.where(user_id: options[:user_ids]).where('operation_id > 0').filter_by(params[:by_preseizure]).distinct.pluck(:report_id).presence || [0]
      end
      options[:ids] = reports_ids if reports_ids.present?

      @reports = Pack::Report.preseizures.joins(:preseizures).where(pack_id: nil).search(options).distinct.order(updated_at: :desc).page(params[:page] || 1).per(params[:per_page] || 20)
    end
  end

  # GET /account/documents/preseizure_account/:id
  def preseizure_account
    @preseizure = Pack::Report::Preseizure.find params[:id]

    user = @preseizure.try(:user)
    @ibiza = user.try(:organization).try(:ibiza)
    @software = @software_human_name = ''
    if user.try(:uses?, :ibiza)
      @software = 'ibiza'
      @software_human_name = 'Ibiza'
    elsif user.try(:uses?, :exact_online)
      @software = 'exact_online'
      @software_human_name = 'Exact Online'
    end

    @unit = @preseizure.try(:unit) || 'EUR'
    @preseizure_entries = @preseizure.entries

    @pre_tax_amount = @preseizure_entries.select { |entry| entry.account.type == 2 }.try(:first).try(:amount) || 0
    analytics = @preseizure.analytic_reference
    @data_analytics = []
    if analytics
      3.times do |i|
        j = i + 1
        references = analytics.send("a#{j}_references")
        name       = analytics.send("a#{j}_name")
        next unless references.present?

        references = JSON.parse(references)
        references.each do |ref|
          if name.present? && ref['ventilation'].present? && (ref['axis1'].present? || ref['axis2'].present? || ref['axis3'].present?)
            @data_analytics << { name: name, ventilation: ref['ventilation'], axis1: ref['axis1'], axis2: ref['axis2'], axis3: ref['axis3'] }
            end
        end
      end
    end

    render partial: 'account/documents/preseizures/preseizure_account'
  end

  def edit_preseizure
    @preseizure = Pack::Report::Preseizure.find params[:id]

    @preseizure_entries = @preseizure.entries

    render partial: 'account/documents/preseizures/edit'
  end

  def update_preseizure
    if @user.has_collaborator_action?
      preseizure = Pack::Report::Preseizure.find params[:id]
      error = ''
      if params[:partial_update].present?
        preseizure.date = params[:date] if params[:date].present?
        if params[:deadline_date].present?
          preseizure.deadline_date  = params[:deadline_date]
        end
        if params[:third_party].present?
          preseizure.third_party    = params[:third_party]
        end

        error = preseizure.errors.full_messages unless preseizure.save
      else
        preseizure.assign_attributes params[:pack_report_preseizure].permit(:date, :deadline_date, :third_party, :operation_label, :piece_number, :amount, :currency, :conversion_rate, :observation)
        if preseizure.conversion_rate_changed? || preseizure.amount_changed?
          preseizure.update_entries_amount
        end

        error = preseizure.errors.full_messages unless preseizure.save
      end

      render json: { error: error }, status: 200
    else
      render json: { error: '' }, status: 200
    end
  end

  def update_multiple_preseizures
    if @user.has_collaborator_action?
      preseizures = Pack::Report::Preseizure.where(id: params[:ids])

      real_params = update_multiple_preseizures_params
      begin
        error = ''
        preseizures.update_all(real_params) if real_params.present?
      rescue StandardError => e
        error = 'Impossible de modifier la séléction'
      end

      render json: { error: error }, status: 200
    else
      render json: { error: '' }, status: 200
    end
  end

  def deliver_preseizures
    if @user.has_collaborator_action?
      if params[:ids].present?
        preseizures = Pack::Report::Preseizure.not_delivered.not_locked.where(id: params[:ids])
      elsif params[:id]
        if params[:type] == 'report'
          reports = Pack::Report.where(id: params[:id])
          if reports.present?
            preseizures = Pack::Report::Preseizure.not_delivered.not_locked
          end
        else
          reports = Pack.find(params[:id]).try(:reports)
          if reports.present?
            preseizures = Pack::Report::Preseizure.not_deleted.not_delivered.not_locked
          end
        end

        if reports.present?
          preseizures = preseizures.where(report_id: reports.collect(&:id))
        end
      end

      if preseizures.present?
        preseizures.group_by(&:report_id).each do |_report_id, preseizures_by_report|
          PreAssignment::CreateDelivery.new(preseizures_by_report, %w[ibiza exact_online my_unisoft]).execute
        end
      end

      render json: { success: true }, status: :ok
    else
      render json: { success: true }, status: 200
    end
  end

  def edit_preseizure_account
    @preseizures = Pack::Report::Preseizure.find params[:id]

    render partial: 'account/documents/preseizures/edit_account'
  end

  def update_preseizure_account
    if @user.has_collaborator_action?
      error = ''
      if params[:type] == 'account'
        account = Pack::Report::Preseizure::Account.find params[:id_account]
        unless account.number = params[:new_value]
          error = account.errors.full_messages
        end
        account.save
      elsif params[:type] == 'entry'
        entry = Pack::Report::Preseizure::Entry.find params[:id_account]
        unless entry.amount = params[:new_value]
          error = entry.errors.full_messages
        end
        entry.save
      else
        entry = Pack::Report::Preseizure::Entry.find params[:id_account]
        unless entry.type = params[:new_value]
          error = entry.errors.full_messages
        end
        entry.save
      end

      render json: { error: error }, status: 200
    else
      render json: { error: '' }, status: 200
    end
  end

  def select_to_export
    if params[:ids]
      obj = Pack::Report::Preseizure.where(id: params[:ids]).limit(1).first
    elsif params[:id]
      obj = if params[:type] == 'report'
              Pack::Report.find params[:id]
            else
              Pack.find params[:id]
            end
    end

    user    = obj.try(:user)
    options = []

    if user
      options << %w[CSV csv] if user.uses?(:csv_descriptor)
      if current_user.is_admin && user.organization.ibiza.try(:configured?) && user.uses?(:ibiza)
        options << ['XML (Ibiza)', 'xml_ibiza']
      end
      options << ['TXT (Quadratus)', 'txt_quadratus']          if user.uses?(:quadratus)
      options << ['ZIP (Quadratus)', 'zip_quadratus']          if user.uses?(:quadratus)
      options << ['ZIP (Coala)', 'zip_coala']                  if user.uses?(:coala)
      options << ['XLS (Coala)', 'xls_coala']                  if user.uses?(:coala)
      options << ['CSV (Cegid)', 'csv_cegid']                  if user.uses?(:cegid)
      options << ['TRA + pièces jointes (Cegid)', 'tra_cegid'] if user.uses?(:cegid)
      options << ['TXT (Fec Agiris)', 'txt_fec_agiris']        if user.uses?(:fec_agiris)
    end

    render json: { options: options }, status: 200
  end

  def export_preseizures
    params64 = Base64.decode64(params[:params64])
    params64 = params64.split('&')

    export_type = params64[0].presence
    export_ids  = params64[1].presence.try(:split, ',')
    export_format = params64[2].presence

    preseizures = []
    if export_ids && export_type == 'preseizure'
      preseizures = Pack::Report::Preseizure.where(id: export_ids)
      if preseizures.any?
        @report = preseizures.first.report

        update_report

        preseizures.reload
      end
    elsif export_ids && export_type == 'report'
      @report = Pack::Report.where(id: export_ids).first

      update_report

      preseizures = Pack::Report.where(id: export_ids).first.preseizures
    elsif export_ids && export_type == 'pack'
      pack    = Pack.where(id: export_ids).first
      reports = pack.present? ? assign_report_with(pack) : []

      preseizures = Pack::Report::Preseizure.not_deleted.where(report_id: reports.collect(&:id))
    end

    supported_format = %w[csv xml_ibiza txt_quadratus zip_quadratus zip_coala xls_coala txt_fec_agiris csv_cegid tra_cegid]

    if preseizures.any? && export_format.in?(supported_format)
      preseizures = preseizures.by_position

      export = PreseizureExport::GeneratePreAssignment.new(preseizures, export_format).generate_on_demand
      if export && export.file_name.present? && export.file_path.present?
        contents = File.read(export.file_path.to_s)

        send_data(contents, filename: File.basename(export.file_name.to_s), disposition: 'attachment')
      else
        render plain: 'Aucun résultat'
      end
    elsif !export_format.in?(supported_format)
      render plain: 'Traitement impossible : le format est incorrect.'
    else
      render plain: 'Aucun résultat'
    end
  end

  # GET /account/documents/:id/archive
  def archive
    pack = Pack.find(params[:id])
    pack = nil unless pack.owner.in?(accounts)

    begin
      if !pack.cloud_archive.attached? || pack.archive_name.gsub('%', '_') != pack.try(:cloud_archive_object).try(:filename)
        pack.save_archive_to_storage #May takes several times
      end

      zip_path = pack.cloud_archive_object.reload.path.presence || pack.archive_file_path

      ok = pack && File.exist?(zip_path)
    rescue => e
      ok = false
    end

    if ok
      send_file(zip_path, type: 'application/zip', filename: pack.archive_name, x_sendfile: true)
    else
      render plain: "File unavalaible"
    end
  end

  def multi_pack_download
    CustomUtils.add_chmod_access_into("/nfs/tmp/")
    _tmp_archive = Tempfile.new(['archive', '.zip'], '/nfs/tmp/')
    _tmp_archive_path = _tmp_archive.path
    _tmp_archive.close
    _tmp_archive.unlink

    params_valid = params[:pack_ids].present?
    ready_to_send = false

    if params_valid
      packs = Pack.where(id: params[:pack_ids].split('_')).order(created_at: :desc)

      files_path = packs.map do |pack|
        document = pack.original_document
        if document && (pack.owner.in?(accounts) || curent_user.try(:is_admin))
          document.cloud_content_object.path
        end
      end
      files_path.compact!

      files_path.in_groups_of(50).each do |group|
        DocumentTools.archive(_tmp_archive_path, group)
      end

      ready_to_send = true if files_path.any? && File.exist?(_tmp_archive_path)
    end

    if ready_to_send
      begin
        contents = File.read(_tmp_archive_path)
        File.unlink _tmp_archive_path if File.exist?(_tmp_archive_path)

        send_data(contents, type: 'application/zip', filename: 'pack_archive.zip', disposition: 'attachment')
      rescue StandardError
        File.unlink _tmp_archive_path if File.exist?(_tmp_archive_path)
        redirect_to account_path, alert: 'Impossible de proceder au téléchargment'
      end
    else
      File.unlink _tmp_archive_path if File.exist?(_tmp_archive_path)
      redirect_to account_path, alert: 'Impossible de proceder au téléchargment'
    end
  end

  # POST /account/documents/sync_with_external_file_storage
  def sync_with_external_file_storage
    if current_user.is_admin
      @packs = params[:pack_ids].present? ? Pack.where(id: params[:pack_ids]) : all_packs
      @packs = @packs.order(created_at: :desc)

      type = params[:type].to_i || FileDelivery::RemoteFile::ALL

      @packs.each do |pack|
        FileDelivery.prepare(pack, users: [@user], type: type, force: true, delay: true)
      end
    end

    respond_to do |format|
      format.html { render body: nil, status: 200 }
      format.json { render json: true, status: :ok }
    end
  end

  # GET /account/documents/processing/:id/download/:style
  def download_processing
    document = TempDocument.find(params[:id])
    owner    = document.temp_pack.user
    filepath = document.cloud_content_object.path(params[:style].presence)

    if File.exist?(filepath) && (owner.in?(accounts) || current_user.try(:is_admin))
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: document.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # GET /account/documents/:id/download/:style
  def download
    begin
      document = params[:id].size > 20 ? Document.find_by_mongo_id(params[:id]) : Document.find(params[:id])
      owner    = document.pack.owner
      filepath = document.cloud_content_object.path(params[:style].presence)
    rescue StandardError
      document = params[:id].size > 20 ? TempDocument.find_by_mongo_id(params[:id]) : TempDocument.find(params[:id])
      owner    = document.temp_pack.user
      filepath = document.cloud_content_object.path(params[:style].presence)
    end

    if File.exist?(filepath) && (owner.in?(accounts) || current_user.try(:is_admin) || params[:token] == document.get_token)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: document.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # GET /account/documents/pieces/:id/download
  def piece
    # NOTE : support old MongoDB id for pieces uploaded to iBiZa, in CSV export or others
    auth_token = params[:token]
    auth_token ||= request.original_url.partition('token=').last

    @piece = params[:id].length > 20 ? Pack::Piece.find_by_mongo_id(params[:id]) : Pack::Piece.unscoped.find(params[:id])
    filepath = @piece.cloud_content_object.path(params[:style].presence || :original)

    if !File.exist?(filepath.to_s) && !@piece.cloud_content.attached?
      sleep 1
      @piece.try(:recreate_pdf)
      filepath = @piece.cloud_content_object.reload.path(params[:style].presence || :original)
    end

    if File.exist?(filepath.to_s) && (@piece.pack.owner.in?(accounts) || current_user.try(:is_admin) || auth_token == @piece.get_token)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: @piece.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # GET /account/documents/pieces/download_selected/:pieces_ids
  def download_selected
    pieces_ids   = params[:pieces_ids].split('_')
    merged_paths = []
    pieces       = []

    pieces_ids.each do |piece_id|
      piece = Pack::Piece.unscoped.find(piece_id)
      file_path = piece.cloud_content_object.path(params[:style].presence || :original)

      if !File.exist?(file_path.to_s) && !piece.cloud_content.attached?
        sleep 1
        piece.try(:recreate_pdf)
        file_path = piece.cloud_content_object.reload.path(params[:style].presence || :original)
      end

      merged_paths << file_path
      pieces << piece
    end

    if pieces.last.user.in?(accounts) || current_user.try(:is_admin)
      tmp_dir      = CustomUtils.mktmpdir('download_selected', nil, false)
      file_path    = File.join(tmp_dir, "#{pieces_ids.size}_selected_pieces.pdf")

      if merged_paths.size > 1
        is_merged = Pdftk.new.merge merged_paths, file_path
      else
        is_merged = true
        FileUtils.cp merged_paths.first, file_path
      end

      if is_merged && File.exist?(file_path.to_s)
        mime_type = File.extname(file_path) == '.png' ? 'image/png' : 'application/pdf'
        send_file(file_path, type: mime_type, filename: File.basename(file_path), x_sendfile: true, disposition: 'inline')
      else
        render body: nil, status: 404
      end
    else
      render body: nil, status: 404
    end
  end

  # GET /account/documents/temp_documents/:id/download
  def temp_document
    auth_token = params[:token]
    auth_token ||= request.original_url.partition('token=').last

    @temp_document = TempDocument.find(params[:id])
    filepath = @temp_document.cloud_content_object.reload.path(params[:style].presence || :original)

    if File.exist?(filepath.to_s) && (@temp_document.user.in?(accounts) || current_user.try(:is_admin) || auth_token == @temp_document.get_token)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: @temp_document.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # GET /contents/original/missing.png
  def handle_bad_url
    token = request.original_url.partition('token=').last

    @piece = Pack::Piece.where('created_at >= ?', '2019-12-28 00:00:00').where('created_at <= ?', '2019-12-31 23:59:59').find_by_token(token)
    filepath = @piece.cloud_content_object.path(:original)

    if File.exist?(filepath)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'

      send_file(filepath, type: mime_type, filename: @piece.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # GET /account/documents/pack/:id/download
  def pack
    @pack = Pack.find params[:id]
    filepath = @pack.cloud_content_object.path

    if File.exist?(filepath) && (@pack.owner.in?(accounts) || current_user.try(:is_admin))
      mime_type = 'application/pdf'
      send_file(filepath, type: mime_type, filename: @pack.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # POST /account/documents/delete_multiple_piece
  def delete_multiple_piece
    pieces    = params[:piece_id]
    pack      = nil

    pieces.each do |piece_id|
      piece           = Pack::Piece.find piece_id
      piece.delete_at = DateTime.now
      piece.delete_by = @user.code
      piece.save

      temp_document = piece.temp_document

      if temp_document
        temp_document.original_fingerprint    = nil
        temp_document.content_fingerprint     = nil
        temp_document.raw_content_fingerprint = nil
        temp_document.save

        parent_document = temp_document.parent_document

        if parent_document && parent_document.children.size == parent_document.children.fingerprint_is_nil.size
          parent_document.original_fingerprint    = nil
          parent_document.content_fingerprint     = nil
          parent_document.raw_content_fingerprint = nil
          parent_document.save
        end
      end

      pack ||= piece.pack
    end

    pack.delay.try(:recreate_original_document)

    render json: { success: true }, status: 200
  end

  # POST /account/documents/restore_piece
  def restore_piece
    piece = Pack::Piece.unscoped.find params[:piece_id]

    piece.delete_at = nil
    piece.delete_by = nil

    piece.save

    temp_document = piece.temp_document

    parent_document = temp_document.parent_document

    temp_document.original_fingerprint = DocumentTools.checksum(temp_document.cloud_content_object.path)
    temp_document.save

    if parent_document
      parent_document.original_fingerprint = DocumentTools.checksum(parent_document.cloud_content_object.path)
      parent_document.save
    end

    pack = piece.pack

    pack.delay.try(:recreate_original_document)

    temp_pack = TempPack.find_by_name(pack.name)

    piece.waiting_pre_assignment if temp_pack.is_compta_processable? && piece.preseizures.size == 0 && piece.temp_document.try(:api_name) != 'invoice_auto' && !piece.pre_assignment_waiting_analytics?

    render json: { success: true }, status: 200
  end

  protected

  def current_layout
    action_name == 'index' ? 'inner' : false
  end

  private

  def update_multiple_preseizures_params
    {
      date: params[:preseizures_attributes][:date].presence,
      deadline_date: params[:preseizures_attributes][:deadline_date].presence,
      third_party: params[:preseizures_attributes][:third_party].presence,
      currency: params[:preseizures_attributes][:currency].presence,
      conversion_rate: params[:preseizures_attributes][:conversion_rate].presence,
      observation: params[:preseizures_attributes][:observation].presence
    }.compact
  end

  def show_pack_pieces
    pack = Pack.find params[:id]

    if params[:by_all].present?
      params[:by_piece] = params[:by_piece].present? ? params[:by_piece].merge(params[:by_all].permit!) : params[:by_all]
    end

    if params[:piece_id].present?
      @documents = pack.pieces.where(id: params[:piece_id]).includes(:pack).order(position: :desc).page(params[:page]).per(2)
    else
      if params[:by_preseizure].present?
        piece_ids = pack.preseizures.filter_by(params[:by_preseizure]).distinct.pluck(:piece_id).presence || [0]
      end

      @documents = pack.pieces
      @documents = @documents.where(id: piece_ids) if piece_ids.present?

      if params[:by_piece].present?
        if params[:by_piece].try(:[], :content)
          @documents = @documents.where('pack_pieces.name LIKE ? OR pack_pieces.tags LIKE ? OR pack_pieces.content_text LIKE ?', "%#{params[:by_piece][:content]}%", "%#{params[:by_piece][:content]}%", "%#{params[:by_piece][:content]}%")
        end
        if params[:by_piece].try(:[], :created_at)
          @documents = @documents.where("DATE_FORMAT(created_at, '%Y-%m-%d') #{params[:by_piece][:created_at_operation].tr('012', ' ><')}= ?", params[:by_piece][:created_at])
        end
        if params[:by_piece].try(:[], :position)
          @documents = @documents.where("position #{params[:by_piece][:position_operation].tr('012', ' ><')}= ?", params[:by_piece][:position])
        end
        if params[:by_piece].try(:[], :tags)
          @documents = @documents.where('tags LIKE ?', "%#{params[:by_piece][:tags]}%")
        end
        if params[:by_piece].try(:[], :state_piece)
          @documents = @documents.where(pre_assignment_state: params[:by_piece][:state_piece].try(:split, ','))
        end
      end

      @documents = @documents.order(position: :desc).includes(:pack).page(params[:page]).per(5)
    end

    user = pack.user
    @ibiza = user.try(:organization).try(:ibiza)

    @pieces_deleted = Pack::Piece.unscoped.where(pack_id: params[:id]).deleted.presence || []

    @software = @software_human_name = ''

    if user.try(:uses?, :ibiza)
      @software = 'ibiza'
      @software_human_name = 'Ibiza'
    elsif user.try(:uses?, :exact_online)
      @software = 'exact_online'
      @software_human_name = 'Exact Online'
    end

    if params[:page].to_i == 1
      @need_delivery = @user.has_collaborator_action? && pack.reports.not_delivered.not_locked.count > 0 ? 'yes' : 'no'
    end

    if params[:page].to_i == 1
      unless pack.is_fully_processed || params[:filter].presence
        @temp_pack      = TempPack.find_by_name(pack.name)
        @temp_documents = @temp_pack.temp_documents.not_published
      end
    end
  end

  def show_report_preseizures
    source = Pack::Report.find params[:id]

    if params[:by_all].present?
      params[:by_preseizure] = params[:by_preseizure].present? ? params[:by_preseizure].merge(params[:by_all].permit!) : params[:by_all]
    end

    if params[:preseizure_ids].present?
      @preseizures = source.preseizures.where(id: params[:preseizure_ids])
    else
      @preseizures = source.preseizures
      @preseizures = @preseizures.filter_by(params[:by_preseizure]).order(position: :desc).distinct.page(params[:page]).per(5)
    end

    user = @preseizures.first.try(:user)
    @ibiza = @preseizures.first.try(:organization).try(:ibiza)

    @software = @software_human_name = ''

    if user.try(:uses?, :ibiza)
      @software = 'ibiza'
      @software_human_name = 'Ibiza'
    elsif user.try(:uses?, :exact_online)
      @software = 'exact_online'
      @software_human_name = 'Exact Online'
    end

    if params[:page].to_i == 1
      @need_delivery = @user.has_collaborator_action? && source.is_not_delivered? && !source.is_locked ? 'yes' : 'no'
    end
  end

  def assign_report_with(pack)
    reports = Pack::Report.where(name: pack.name.gsub('all', '').strip)
    if reports.any?
      reports.each do |report|
        report.update(pack_id: pack.id) if report.pack_id.nil? && report.preseizures.first.try(:piece_id).present?
      end

      reports.reload
    end

    reports
  end

  def update_report
    if @report && @report.name
      pack = Pack.where(name: @report.name + ' all').first
      assign_report_with(pack) if pack.present?
    end
  end
end
