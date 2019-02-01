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

    @packs            = Pack.search(params[:text], options)
    @last_composition = @user.composition

    ### TODO : GET DOCUMENTS COMPOSITION FROM PIECES INSTEAD OF DOCUMENTS FOR COMPOSITION CREATED AFTER 23/01/2019
    @composition      = nil #TEMP FIX
    # @composition      = Document.where(id: @last_composition.document_ids) if @last_composition
    ######################

    @period_service   = PeriodService.new user: @user

    @pack = Pack.where(owner_id: options[:owner_ids], name: params[:pack_name]).first if params[:pack_name].present?
  end

  # GET /account/documents/:id
  def show
    @pack = Pack.where(owner_id: account_ids, id: params[:id]).first!
    @data_type = params[:fetch] || 'pieces'

    if  @data_type == 'preseizures'
      if(params[:piece_id].present?)
        @preseizures = Pack::Report::Preseizure.where(piece_id: params[:piece_id]).order(position: :desc).distinct.page(params[:page]).per(10)
      else
        @preseizures = Pack::Report::Preseizure.where(report_id: @pack.reports.collect(&:id))

        @preseizures = @preseizures.delivered         if params[:is_delivered].present? && params[:is_delivered].to_i == 1
        @preseizures = @preseizures.not_delivered     if params[:is_delivered].present? && params[:is_delivered].to_i == 2
        @preseizures = @preseizures.failed_delivery   if params[:is_delivered].present? && params[:is_delivered].to_i == 3

        @preseizures = @preseizures.where("DATE_FORMAT(created_at, '%Y-%m-%d') #{params[:created_at_operation].tr('012', ' ><')}= ?", params[:created_at])                       if params[:created_at].present?
        @preseizures = @preseizures.where("DATE_FORMAT(delivery_tried_at, '%Y-%m-%d') #{params[:delivery_tried_at_operation].tr('012', ' ><')}= ?", params[:delivery_tried_at])  if params[:delivery_tried_at].present?
        @preseizures = @preseizures.where("amount #{params[:amount_operation].tr('012', ' ><')}= ?", params[:amount])                                                            if params[:amount].present?
        @preseizures = @preseizures.where("position #{params[:position_operation].tr('012', ' ><')}= ?", params[:position])                                                      if params[:position].present?

        @preseizures = @preseizures.where(piece_number: params[:piece_number])  if params[:piece_number].present?
        @preseizures = @preseizures.where(third_party: params[:third_party])    if params[:third_party].present?

        @preseizures = @preseizures.order(position: :desc).distinct.page(params[:page]).per(10)
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

      @need_delivery = @pack.reports.not_delivered.not_locked.count > 0 ? 'yes' : 'no' if params[:page].to_i == 1
    else
      if params[:piece_id].present?
        @documents = Pack::Piece.where(id: params[:piece_id]).includes(:pack).order(position: :desc).page(params[:page]).per(20)
      else
        @documents = Pack::Piece.search(params[:filter],
          pack_id:  params[:id]
        ).order(position: :desc).includes(:pack).page(params[:page]).per(20)
      end

      if params[:page].to_i == 1
        unless @pack.is_fully_processed || params[:filter].presence
          @temp_pack      = TempPack.find_by_name(@pack.name)
          @temp_documents = @temp_pack.temp_documents.not_published
        end
      end
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
      options = { page: params[:page], per_page: params[:per_page] }
      options[:sort] = true

      options[:owner_ids] = if params[:view].present? && params[:view] != 'all'
        _user = accounts.find(params[:view])
        _user ? [_user.id] : []
      else
        account_ids
      end

      piece_ids = Pack::Report::Preseizure.where(user_id: options[:owner_ids], operation_id: ['', nil]).filter_by(params[:by_preseizure]).distinct.pluck(:piece_id).presence || [0] if params[:by_preseizure].present?

      options[:piece_ids] = piece_ids if piece_ids.present?

      @packs = Pack.search(params[:text], options).distinct.order(updated_at: :desc).page(options[:page]).per(options[:per_page])
    end
  end

  #GET /account/documents/preseizure_account/:id
  def preseizure_account
    preseizure = Pack::Report::Preseizure.find params[:id]
    @unit = preseizure.try(:unit) || 'EUR'
    @preseizure_entries = preseizure.entries
    @pre_tax_amount = @preseizure_entries.select{ |entry| entry.account.type == 2 }.try(:first).try(:amount) || 0
    
    analytics = preseizure.analytic_reference
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

    render partial: 'account/documents/preseizures/edit'
  end

  def update_preseizure
    preseizure = Pack::Report::Preseizure.find params[:id]

    error = ''
    error = preseizure.errors.full_messages unless preseizure.update_attributes params[:pack_report_preseizure].permit(:date, :deadline_date, :third_party, :operation_label, :piece_number, :amount, :currency, :conversion_rate, :observation)

    render json: { error: error }, status: 200
  end

  def update_multiple_preseizures
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

  def deliver_preseizures
    if params[:ids].present?
      preseizures = Pack::Report::Preseizure.not_delivered.not_locked.where(id: params[:ids])
    elsif params[:pack_id]
      reports = Pack.find(params[:pack_id]).try(:reports)
      preseizures = Pack::Report::Preseizure.not_delivered.not_locked.where(report_id: reports.collect(&:id)) if reports.present?
    end

    if preseizures.present?
      preseizures.group_by(&:report_id).each do |report_id, preseizures_by_report|
        CreatePreAssignmentDeliveryService.new(preseizures_by_report, ['ibiza', 'exact_online']).execute
      end
    end

    render json: { success: true }, status: :ok
  end

  def edit_preseizure_account
    @account = Pack::Report::Preseizure::Account.find params[:id]

    render partial: 'account/documents/preseizures/edit_account'
  end

  def update_preseizure_account
    account = Pack::Report::Preseizure::Account.find params[:id]

    error = ''
    error = account.errors.full_messages unless account.update_attributes params[:pack_report_preseizure_account].permit(:number, :lettering)

    render json: { error: error }, status: 200
  end

  def edit_preseizure_entry
    @entry = Pack::Report::Preseizure::Entry.find params[:id]

    render partial: 'account/documents/preseizures/edit_entry'
  end

  def update_preseizure_entry
    entry = Pack::Report::Preseizure::Entry.find params[:id]

    error = ''
    error = entry.errors.full_messages unless entry.update_attributes params[:pack_report_preseizure_entry].permit(:type, :amount)

    render json: { error: error }, status: 200
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
end
