# -*- encoding : UTF-8 -*-
class Account::DocumentsController < Account::AccountController
  layout :current_layout

  skip_before_filter :login_user!, :only => %w(download piece)

protected
  def current_layout
    action_name == 'index' ? 'inner' : false
  end

public
  def index
    options = {}
    if @user.is_prescriber
      owner_ids = [@user.id.to_s] + @user.customer_ids.map(&:to_s)
      options[:owner_ids] = owner_ids
    else
      options[:owner_id] = @user.id
    end
    options.merge!({ page: params[:page], per_page: params[:per_page], sort: true })
    @response = Pack.search(params[:filter], options)
    @packs = @response.records.records.desc(:updated_at)

    @last_composition = @user.composition
    @composition = Document.any_in(:_id => @last_composition.document_ids) if @last_composition
    @period_service = PeriodService.new user: @user
    if params[:pack_name].present?
      owner_ids = [options[:owner_id]].compact.presence || options[:owner_ids]
      @pack = Pack.where(:owner_id.in => owner_ids, name: params[:pack_name]).first
    end
  end

  def show
    @pack = @user.packs.find(params[:id])
    raise Mongoid::Errors::DocumentNotFound.new(Pack, nil, params[:id]) unless @pack
    @response = Document.search(params[:filter],
      pack_id:  params[:id],
      per_page: 10000,
      sort:     true
    )
    @documents = @response.records.records.where(:origin.nin => ['mixed']).asc(:position)
    unless @pack.is_fully_processed || params[:filter].presence
      @temp_pack = TempPack.find_by_name(@pack.name)
      @temp_documents = @temp_pack.temp_documents.not_published
    end
  end

  def packs
    if params[:view] == "current_delivery"
      pack_ids = @user.remote_files.not_processed.distinct(:pack_id)
      @packs = @user.packs.any_in(_id: pack_ids)
      @remaining_files = @user.remote_files.not_processed.count
      @packs = @packs.desc(:updated_at).page(params[:page]).per(params[:per_page])
    else
      options = { page: params[:page], per_page: params[:per_page] }
      options.merge!({ sort: true }) unless params[:filter].present?
      if @user.is_prescriber
        owner_ids = []
        if params[:view].present? && params[:view] != 'all'
          @other_user = @user.customers.find(params[:view])
          owner_ids = [@other_user.id.to_s] if @other_user
        else
          owner_ids = [@user.id.to_s] + @user.customer_ids.map(&:to_s)
        end
        options.merge!({ owner_ids: owner_ids })
      else
        options.merge!({ owner_id: @user.id.to_s })
      end
      @response = Pack.search(params[:filter], options)
      @packs = @response.records.records
      @packs = @packs.desc(:updated_at) unless params[:filter].present?
    end
  end

  def archive
    pack = Pack.find(params[:id])
    if @user.is_prescriber
      pack = pack.owner.in?(@user.customers) ? pack : nil
    else
      pack = pack.owner == @user ? pack : nil
    end
    raise Mongoid::Errors::DocumentNotFound.new(Pack, nil, params[:id]) unless pack

    if File.exist? pack.archive_file_path
      send_file(pack.archive_file_path, type: 'application/zip', filename: pack.archive_name, x_sendfile: true)
    else
      render text: 'File unavalaible'
    end
  end

  def sync_with_external_file_storage
    if current_user.is_admin
      if params[:pack_ids].present?
        @packs = Pack.where(:_id.in => params[:pack_ids])
      else
        @packs = @user.packs
      end
      @packs = @packs.desc(:created_at)
      type = params[:type].to_i || FileDeliveryInit::RemoteFile::ALL

      @packs.each do |pack|
        FileDeliveryInit.prepare(pack, users: [@user], type: type, force: true, delay: true)
      end
    end

    respond_to do |format|
      format.html { render nothing: true, status: 200 }
      format.json { render json: true, status: :ok }
    end
  end

  def download
    begin
      document = Document.find params[:id]
      owner = document.pack.owner
    rescue
      document = TempDocument.find params[:id]
      owner = document.temp_pack.user
    end
    filepath = document.content.path(params[:style])
    users = []
    if @user
      if @user.is_prescriber
        users = @user.customers
      else
        users = [@user]
      end
    end
    if File.exist?(filepath) && (owner.in?(users) || current_user.try(:is_admin) || params[:token] == document.get_token)
      filename = File.basename(filepath)
      if File.extname(filepath) == '.png'
        mime_type = 'image/png'
      else
        mime_type = 'application/pdf'
      end
      send_file(filepath, type: mime_type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  def piece
    begin
      piece = Pack::Piece.find params[:id]
      filepath = piece.content.path
      users = []
      if @user
        if @user.is_prescriber
          users = @user.customers
        else
          users = [@user]
        end
      end
      if File.exist?(filepath) && (piece.pack.owner.in?(users) || current_user.try(:is_admin) || params[:token] == piece.get_token)
        filename = File.basename(filepath)
        type = piece.content_content_type || 'application/pdf'
        send_file(filepath, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
      else
        render nothing: true, status: 404
      end
    rescue Mongoid::Errors::DocumentNotFound
      render nothing: true, status: 404
    end
  end
end
