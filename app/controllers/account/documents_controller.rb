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

    @packs            = Pack.search(params[:filter], options)
    @last_composition = @user.composition
    @composition      = Document.where(id: @last_composition.document_ids) if @last_composition
    @period_service   = PeriodService.new user: @user

    @pack = Pack.where(owner_id: options[:owner_ids], name: params[:pack_name]).first if params[:pack_name].present?
  end

  # GET /account/documents/:id
  def show
    @pack = Pack.where(owner_id: account_ids, id: params[:id]).first!

    @documents = Document.search(params[:filter],
      pack_id:  params[:id],
      per_page: 10_000,
      sort:     true
    ).where.not(origin: ['mixed']).order(position: :asc).includes(:pack)

    unless @pack.is_fully_processed || params[:filter].presence
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
      options[:sort] = true unless params[:filter].present?

      options[:owner_ids] = if params[:view].present? && params[:view] != 'all'
        _user = accounts.find(params[:view])
        _user ? [_user.id] : []
      else
        account_ids
      end

      @packs = Pack.search(params[:filter], options)
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
    document = Document.find(params[:id])
    owner    = document.pack.owner
    filepath = document.content.path(params[:style].presence)

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
    if File.exist?(@piece.content.path) && (@piece.pack.owner.in?(accounts) || current_user.try(:is_admin) || params[:token] == @piece.get_token)
      type = @piece.content_content_type || 'application/pdf'
      send_file(@piece.content.path, type: type, filename: @piece.content_file_name, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

protected

  def current_layout
    action_name == 'index' ? 'inner' : false
  end
end
