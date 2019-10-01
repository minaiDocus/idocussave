# -*- encoding : UTF-8 -*-
class Account::DocumentsController < Account::AccountController
  layout :current_layout

  skip_before_filter :login_user!, only: %w(download piece)

  # GET /account/documents
  def index
    options = {
      owner_ids: account_ids,
      page:      params[:page],
      per_page:  params[:per_page],
      sort:      true
    }

    if params[:pack_name].present?
      @packs = Pack.where(owner_id: options[:owner_ids], name: params[:pack_name]).page(options[:page]).per(options[:per_page])
      ### TODO: find a better way to get empty reports with kaminari classes / methods
      @reports = @packs.first.reports.where(pack_id: nil).page(options[:page]).per(options[:per_page])
    else
      @packs   = Pack.search(params.try(:[], :by_piece).try(:[], :content), options)
      @reports = Pack::Report.where(user_id: options[:owner_ids], pack_id: nil).order(updated_at: :desc).page(options[:page]).per(options[:per_page])
    end

    @last_composition = @user.composition

    ### TODO : GET DOCUMENTS COMPOSITION FROM PIECES INSTEAD OF DOCUMENTS FOR COMPOSITION CREATED AFTER 23/01/2019
    @composition      = nil #TEMP FIX
    # @composition      = Document.where(id: @last_composition.document_ids) if @last_composition
    ######################

    @period_service   = PeriodService.new user: @user
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
      @packs = Pack.where(owner_id: account_ids, id: pack_ids).
        order(updated_at: :desc).
        page(params[:page]).
        per(params[:per_page])
      @remaining_files = @user.remote_files.not_processed.count
    else
      if params[:by_all].present?
        params[:by_piece] = params[:by_piece].present? ? params[:by_piece].merge(params[:by_all]) : params[:by_all]
        params[:by_preseizure] = params[:by_preseizure].present? ? params[:by_preseizure].merge(params[:by_all]) : params[:by_all]
      end

      options = { page: params[:page], per_page: params[:per_page] }
      options[:sort] = true

      options[:piece_created_at] = params[:by_piece].try(:[], :created_at)
      options[:piece_created_at_operation] = params[:by_piece].try(:[], :created_at_operation)

      options[:piece_position] = params[:by_piece].try(:[], :position)
      options[:piece_position_operation] = params[:by_piece].try(:[], :position_operation)

      options[:name] = params[:by_pack].try(:[], :pack_name)
      options[:tags] = params[:by_piece].try(:[], :tags)

      options[:owner_ids] = if params[:view].present? && params[:view] != 'all'
        _user = accounts.find(params[:view])
        _user ? [_user.id] : []
      else
        account_ids
      end

      piece_ids = Pack::Report::Preseizure.where(user_id: options[:owner_ids], operation_id: ['', nil]).filter_by(params[:by_preseizure]).distinct.pluck(:piece_id).presence || [0] if params[:by_preseizure].present?

      options[:piece_ids] = piece_ids if piece_ids.present?

      @packs = Pack.search(params.try(:[], :by_piece).try(:[], :content), options).distinct.order(updated_at: :desc).page(options[:page]).per(options[:per_page])
    end
  end

  def reports
    if params[:view] == 'current_delivery'
      #send empty ActiveRelation
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
        params[:by_preseizure] = params[:by_preseizure].present? ? params[:by_preseizure].merge(params[:by_all]) : params[:by_all]
      end

      options[:name] = params[:by_pack].try(:[], :pack_name)

      reports_ids = Pack::Report::Preseizure.where(user_id: options[:user_ids]).where('operation_id > 0').filter_by(params[:by_preseizure]).distinct.pluck(:report_id).presence || [0] if params[:by_preseizure].present?
      options[:ids] = reports_ids if reports_ids.present?

      @reports = Pack::Report.preseizures.joins(:preseizures).where(pack_id: nil).search(options).distinct.order(updated_at: :desc).page(params[:page] || 1).per(params[:per_page] || 20)
    end
  end

  #GET /account/documents/preseizure_account/:id
  def preseizure_account
    @preseizure = Pack::Report::Preseizure.find params[:id]

    user = @preseizure.try(:user)
    @ibiza = user.try(:organization).try(:ibiza)
    @software = @software_human_name = ''
    if user.try(:uses_ibiza?)
      @software = 'ibiza'
      @software_human_name = 'Ibiza'
    elsif user.try(:uses_exact_online?)
      @software = 'exact_online'
      @software_human_name = 'Exact Online'
    end

    @unit = @preseizure.try(:unit) || 'EUR'
    @preseizure_entries = @preseizure.entries
    @pre_tax_amount = @preseizure_entries.select{ |entry| entry.account.type == 2 }.try(:first).try(:amount) || 0
    
    analytics = @preseizure.analytic_reference
    @data_analytics = []
    if analytics 
      3.times do |i|
        j = i + 1
        references = analytics.send("a#{j}_references")
        name       = analytics.send("a#{j}_name")
        if references.present?
          references = JSON.parse(references)
          references.each do |ref|
            @data_analytics << { name: name, ventilation: ref['ventilation'], axis1: ref['axis1'], axis2: ref['axis2'], axis3: ref['axis3'] } if name.present? && ref['ventilation'].present? && (ref['axis1'].present? || ref['axis2'].present? || ref['axis3'].present?)
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
    unless @user.collaborator?
      render json: { error: '' }, status: 200
    else
      preseizure = Pack::Report::Preseizure.find params[:id]

      error = ''

      preseizure.assign_attributes params[:pack_report_preseizure].permit(:date, :deadline_date, :third_party, :operation_label, :piece_number, :amount, :currency, :conversion_rate, :observation)
      preseizure.update_entries_amount if preseizure.conversion_rate_changed? || preseizure.amount_changed?

      error = preseizure.errors.full_messages unless preseizure.save

      render json: { error: error }, status: 200
    end
  end

  def update_multiple_preseizures
    unless @user.collaborator?
      render json: { error: '' }, status: 200
    else
      preseizures = Pack::Report::Preseizure.where(id: params[:ids])

      real_params = update_multiple_preseizures_params
      begin
        error = ''
        preseizures.update_all(real_params) if real_params.present?
      rescue => e
        error = 'Impossible de modifier la séléction'
      end

      render json: { error: error }, status: 200
    end
  end

  def deliver_preseizures
    unless @user.collaborator?
      render json: { success: true }, status: 200
    else
      if params[:ids].present?
        preseizures = Pack::Report::Preseizure.not_delivered.not_locked.where(id: params[:ids])
      elsif params[:id]
        if params[:type] == 'report'
          reports = Pack::Report.where(id: params[:id])
        else
          reports = Pack.find(params[:id]).try(:reports)
        end

        preseizures = Pack::Report::Preseizure.not_delivered.not_locked.where(report_id: reports.collect(&:id)) if reports.present?
      end

      if preseizures.present?
        preseizures.group_by(&:report_id).each do |report_id, preseizures_by_report|
          CreatePreAssignmentDeliveryService.new(preseizures_by_report, ['ibiza', 'exact_online']).execute
        end
      end

      render json: { success: true }, status: :ok
    end
  end

  def edit_preseizure_account
    @preseizures = Pack::Report::Preseizure.find params[:id]

    render partial: 'account/documents/preseizures/edit_account'
  end

  def update_preseizure_account
    unless @user.collaborator?
      render json: { error: '' }, status: 200
    else
      error = ''
      params[:account_id].each do |id|
        account = Pack::Report::Preseizure::Account.find id
        error = account.errors.full_messages unless account.number = params[:entry_account_number][id]
        error = account.errors.full_messages unless account.lettering = params[:entry_account_lettrage][id]
        account.save
      end

      params[:entry_id].each do |id|
        entry = Pack::Report::Preseizure::Entry.find id
        error = entry.errors.full_messages unless entry.type = params[:entry_type][id]
        error = entry.errors.full_messages unless entry.amount = params[:entry_amount_number][id]
        entry.save
      end      

      render json: { error: error }, status: 200
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

    user = obj.user

    options = []
    options << ['CSV', 'csv']                       if user.uses_csv_descriptor?
    options << ['XML (Ibiza)', 'xml_ibiza']         if current_user.is_admin && user.organization.ibiza.try(:configured?) && user.uses_ibiza?
    options << ['ZIP (Quadratus)', 'zip_quadratus'] if user.uses_quadratus?
    options << ['ZIP (Coala)', 'zip_coala']         if user.uses_coala?
    options << ['XLS (Coala)', 'xls_coala']         if user.uses_coala?
    options << ['CSV (Cegid)', 'csv_cegid']         if user.uses_cegid?

    render json: { options: options }, status: 200
  end

  def export_preseizures
    params64 = Base64.decode64(params[:params64])
    params64 = params64.split('&')

    export_type = params64[0].presence
    export_ids = params64[1].presence
    export_format = params64[2].presence

    if export_ids && export_type == 'preseizure'
      preseizures = Pack::Report::Preseizure.where("id IN (#{export_ids})")
    elsif export_ids && export_type == 'report'
      preseizures = Pack::Report.where(id: export_ids).first.preseizures
    elsif export_ids && export_type == 'pack'
      reports     = Pack.where(id: export_ids).first.reports
      preseizures = Pack::Report::Preseizure.where(report_id: reports.collect(&:id))
    end

    preseizures = preseizures.by_position
    report      = preseizures.first.try(:report)
    user        = preseizures.first.try(:user)

    case export_format
      when 'csv'
        if preseizures.any? && user.try(:uses_csv_descriptor?)
          data = PreseizuresToCsv.new(user, preseizures).execute

          send_data(data, type: 'text/csv', filename: "#{report.name.tr(' ', '_')}.csv")
        else
          render text: 'Aucun résultat'
        end
      when 'xml_ibiza'
        if current_user.is_admin
          if preseizures.any?
            file_name = "#{report.name.tr(' ', '_')}.xml"

            ibiza = user.organization.ibiza

            if ibiza.try(:configured?) && user.try(:ibiza_id) && user.try(:uses_ibiza?)
              date = DocumentTools.to_period(report.name)

              exercise = IbizaExerciseFinder.new(user, date, ibiza).execute
              if exercise
                data = IbizaAPI::Utils.to_import_xml(exercise, preseizures, ibiza.description, ibiza.description_separator, ibiza.piece_name_format, ibiza.piece_name_format_sep)

                send_data(data, type: 'application/xml', filename: file_name)
              else
                render text: 'Traitement impossible'
              end
            else
              render text: 'Traitement impossible'
            end
          else
            render text: 'Aucun résultat'
          end
        end
      when 'zip_quadratus'
        if preseizures.any? && user.try(:uses_quadratus?)
          file_path = QuadratusZipService.new(preseizures).execute

          logger.info(file_path.inspect)

          send_file(file_path, type: 'application/zip', filename: File.basename(file_path), x_sendfile: true)
        else
          render text: 'Aucun résultat'
        end
      when 'zip_coala'
        if preseizures.any? && user.try(:uses_coala?)
          file_path = CoalaZipService.new(user, preseizures, {to_xls: true}).execute
          send_file(file_path, type: 'application/zip', filename: File.basename(file_path), x_sendfile: true)
        else
          render text: 'Aucun résultat'
        end
      when 'xls_coala'
        if preseizures.any? && user.organization.is_coala_used && user.try(:uses_coala?)
          file_path = CoalaZipService.new(user, preseizures, {preseizures_only: true, to_xls: true}).execute
          send_file(file_path, type: 'text/xls', filename: File.basename(file_path), x_sendfile: true)
        else
          render text: 'Aucun résultat'
        end
      when 'csv_cegid'
        if preseizures.any? && user.uses_cegid?
          file_path = CegidZipService.new(user, preseizures).execute
          send_file(file_path, type: 'text/csv', filename: File.basename(file_path), x_sendfile: true)
        else
          render text: 'Aucun résultat'
        end
      else
        render text: 'Traitement impossible'
    end
  end

  # GET /account/documents/:id/archive
  def archive
    pack = Pack.find(params[:id])
    pack = nil unless pack.owner.in?(accounts)

    if pack && File.exist?(pack.archive_file_path)
      send_file(pack.archive_file_path, type: 'application/zip', filename: pack.archive_name, x_sendfile: true)
    else
      render text: 'File unavalaible'
    end
  end

  def multi_pack_download
    _tmp_archive = Tempfile.new(['archive', '.zip'])
    _tmp_archive_path = _tmp_archive.path
    _tmp_archive.close
    _tmp_archive.unlink

    params_valid = params[:pack_ids].present?
    ready_to_send = false

    if params_valid
      packs = Pack.where(id: params[:pack_ids].split("_")).order(created_at: :desc)

      files_path = packs.map do |pack|
        document = pack.original_document
        if document && (pack.owner.in?(accounts) || curent_user.try(:is_admin))
          document.content.path('original')
        else
          nil
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
      rescue
        File.unlink _tmp_archive_path if File.exist?(_tmp_archive_path)
        redirect_to account_path, alert: "Impossible de proceder au téléchargment"
      end
    else
      File.unlink _tmp_archive_path if File.exist?(_tmp_archive_path)
      redirect_to account_path, alert: "Impossible de proceder au téléchargment"
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
      format.html { render nothing: true, status: 200 }
      format.json { render json: true, status: :ok }
    end
  end

  # GET /account/documents/processing/:id/download/:style
  def download_processing
    document = TempDocument.find(params[:id])
    owner    = document.temp_pack.user
    filepath = document.content.path(params[:style].presence)

    if File.exist?(filepath) && (owner.in?(accounts) || current_user.try(:is_admin))
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: document.content_file_name, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  # GET /account/documents/:id/download/:style
  def download
    begin
      document = params[:id].size > 20 ? Document.find_by_mongo_id(params[:id]) : Document.find(params[:id])
      owner    = document.pack.owner
      filepath = document.content.path(params[:style].presence)
    rescue
      document = params[:id].size > 20 ? TempDocument.find_by_mongo_id(params[:id]) : TempDocument.find(params[:id])
      owner    = document.temp_pack.user
      filepath = document.content.path(params[:style].presence)
    end

    if File.exist?(filepath) && (owner.in?(accounts) || current_user.try(:is_admin) || params[:token] == document.get_token)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: document.content_file_name, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  # GET /account/documents/pieces/:id/download
  def piece
    # NOTE : support old MongoDB id for pieces uploaded to iBiZa, in CSV export or others
    @piece = params[:id].length > 20 ? Pack::Piece.find_by_mongo_id(params[:id]) : Pack::Piece.find(params[:id])
    filepath = @piece.content.path(params[:style].presence || :original)

    if File.exist?(filepath) && (@piece.pack.owner.in?(accounts) || current_user.try(:is_admin) || params[:token] == @piece.get_token)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: @piece.content_file_name, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  # GET /account/documents/pack/:id/download
  def pack
    @pack = Pack.find params[:id]
    filepath = @pack.content.path

    if File.exist?(filepath) && (@pack.owner.in?(accounts) || current_user.try(:is_admin))
      mime_type = 'application/pdf'           
      send_file(filepath, type: mime_type, filename: @pack.content_file_name, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
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
      
      temp_piece      = piece.temp_document
      temp_piece.original_fingerprint    = nil 
      temp_piece.content_fingerprint     = nil 
      temp_piece.raw_content_fingerprint = nil 
      temp_piece.save

      pack ||= piece.pack
    end    

    pack.delay.try(:recreate_original_document)        
    
    render json: { success: true }, status: 200    
  end

protected

  def current_layout
    action_name == 'index' ? 'inner' : false
  end

private
  def update_multiple_preseizures_params
    {
      date:               params[:preseizures_attributes][:date].presence,
      deadline_date:      params[:preseizures_attributes][:deadline_date].presence,
      third_party:        params[:preseizures_attributes][:third_party].presence,
      currency:           params[:preseizures_attributes][:currency].presence,
      conversion_rate:    params[:preseizures_attributes][:conversion_rate].presence,
      observation:        params[:preseizures_attributes][:observation].presence,
    }.compact
  end


  def show_pack_pieces

    pack = Pack.find params[:id]
    
    if params[:by_all].present?
      params[:by_piece] = params[:by_piece].present? ? params[:by_piece].merge(params[:by_all]) : params[:by_all]
      params[:by_preseizure] = params[:by_preseizure].present? ? params[:by_preseizure].merge(params[:by_all]) : params[:by_all]
    end
    
    if(params[:piece_id].present?)
      @documents = pack.pieces.where(id: params[:piece_id]).includes(:pack).order(position: :desc).page(params[:page]).per(2)
    else
      piece_ids = pack.preseizures.filter_by(params[:by_preseizure]).distinct.pluck(:piece_id).presence || [0] if params[:by_preseizure].present?

      @documents = pack.pieces
      @documents = @documents.where(id: piece_ids) if piece_ids.present?

      if(params[:by_piece].present?)
        @documents = @documents.where("pack_pieces.name LIKE ? OR pack_pieces.tags LIKE ? OR pack_pieces.content_text LIKE ?", "%#{params[:by_piece][:content]}%", "%#{params[:by_piece][:content]}%", "%#{params[:by_piece][:content]}%") if params[:by_piece].try(:[], :content)
        @documents = @documents.where("DATE_FORMAT(created_at, '%Y-%m-%d') #{params[:by_piece][:created_at_operation].tr('012', ' ><')}= ?", params[:by_piece][:created_at]) if params[:by_piece].try(:[], :created_at) 
        @documents = @documents.where("position #{params[:by_piece][:position_operation].tr('012', ' ><')}= ?", params[:by_piece][:position]) if params[:by_piece].try(:[], :position)
        @documents = @documents.where("tags LIKE ?", "%#{params[:by_piece][:tags]}%") if params[:by_piece].try(:[], :tags)
      end

      @documents = @documents.order(position: :desc).includes(:pack).page(params[:page]).per(5)
    end

    user = pack.user
    @ibiza = user.try(:organization).try(:ibiza)

    @software = @software_human_name = ''
    
    if user.try(:uses_ibiza?)
      @software = 'ibiza'
      @software_human_name = 'Ibiza'
    elsif user.try(:uses_exact_online?)
      @software = 'exact_online'
      @software_human_name = 'Exact Online'
    end

    @need_delivery = (@user.collaborator? && pack.reports.not_delivered.not_locked.count > 0) ? 'yes' : 'no' if params[:page].to_i == 1

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
      params[:by_preseizure] = params[:by_preseizure].present? ? params[:by_preseizure].merge(params[:by_all]) : params[:by_all]
    end
    
    if(params[:preseizure_ids].present?)
       @preseizures = source.preseizures.where(id: params[:preseizure_ids])
    else
      @preseizures = source.preseizures
      @preseizures = @preseizures.filter_by(params[:by_preseizure]).order(position: :desc).distinct.page(params[:page]).per(5)
    end

    user = @preseizures.first.try(:user)
    @ibiza = @preseizures.first.try(:organization).try(:ibiza)

    @software = @software_human_name = ''
    
    if user.try(:uses_ibiza?)
      @software = 'ibiza'
      @software_human_name = 'Ibiza'
    elsif user.try(:uses_exact_online?)
      @software = 'exact_online'
      @software_human_name = 'Exact Online'
    end

    @need_delivery = (@user.collaborator? && source.is_not_delivered? && !source.is_locked)? 'yes' : 'no' if params[:page].to_i == 1
  end
end
