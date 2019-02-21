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

    piece_ids = @pack.preseizures.filter_by(params[:by_preseizure]).distinct.pluck(:piece_id).presence || [0] if params[:by_preseizure].present?

    @documents = Pack::Piece.search(  params[:text],
                                      pack_id:  params[:id]
                                    )
    @documents = @documents.where(id: piece_ids) unless piece_ids.nil?

    @documents = @documents.order(position: :asc).includes(:pack).per(10_000)

    unless @pack.is_fully_processed || params[:text].presence
      @temp_pack      = TempPack.find_by_name(@pack.name)
      @temp_documents = @temp_pack.temp_documents.not_published
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
end
