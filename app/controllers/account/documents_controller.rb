# -*- encoding : UTF-8 -*-
class Account::DocumentsController < Account::AccountController
  layout :current_layout

  skip_before_filter :login_user!, :only => %w(download piece)

protected
  def current_layout
    action_name == 'index' ? 'inner' : nil
  end

public
  def index
    options = {}
    if @user.organization && @user.is_prescriber
      owner_ids = [@user.id.to_s] + @user.customer_ids.map(&:to_s)
      options[:owner_ids] = owner_ids
    else
      options[:owner_id] = @user.id
    end
    @packs = Pack.search(params[:filter], { page: params[:page] || 1, per_page: params[:per_page] || 20 }.merge(options))
    @packs_count = @packs.total

    @last_composition = @user.composition
    @composition = Document.any_in(:_id => @last_composition.document_ids) if @last_composition
    @period_service = PeriodService.new user: @user
    if params[:pack_name].present?
      owner_ids = [options[:owner_id]].presence || options[:owner_ids]
      @pack = Pack.where(:owner_id.in => owner_ids, name: params[:pack_name]).first
    end
  end

  def show
    @pack = @user.packs.find(params[:id])
    raise Mongoid::Errors::DocumentNotFound.new(Pack, params[:id]) unless @pack
    @documents = Document.search(params[:filter], pack_id: params[:id], origin: ['scan', 'upload', 'dematbox_scan', 'fiduceo'], per_page: 10000)
  end

  def packs
    if params[:view] == "current_delivery"
      pack_ids = @user.remote_files.not_processed.distinct(:pack_id)
      @packs = @user.packs.any_in(_id: pack_ids)
      @remaining_files = @user.remote_files.not_processed.count
      @packs_count = @packs.count
      @packs = @packs.page(params[:page]).per(params[:per_page])
    else
      if @user.organization && @user.is_prescriber
        owner_ids = []
        if params[:view].present? && params[:view] != 'all'
          @other_user = @user.customers.find(params[:view])
          owner_ids = [@other_user.id.to_s] if @other_user
        else
          owner_ids = [@user.id.to_s] + @user.customer_ids.map(&:to_s)
        end
        @packs = Pack.search(params[:filter], owner_ids: owner_ids, page: params[:page], per_page: params[:per_page])
      else
        @packs = Pack.search(params[:filter], owner_id: @user.id.to_s, page: params[:page], per_page: params[:per_page])
      end
      @packs_count = @packs.total rescue 0
    end
  end

  def archive
    pack = Pack.find(params[:id])
    if @user.organization && @user.is_prescriber
      pack = pack.owner.in?(@user.customers) ? pack : nil
    else
      pack = pack.owner == @user ? pack : nil
    end
    raise Mongoid::Errors::DocumentNotFound.new(Pack, params[:id]) unless pack

    if File.exist? pack.archive_file_path
      send_file(pack.archive_file_path, type: 'application/zip', filename: pack.archive_name, x_sendfile: true)
    else
      render text: 'File unavalaible'
    end
  end

  def sync_with_external_file_storage
    if current_user.is_admin
      if params[:pack_ids].present?
        @packs = Pack.find(params[:pack_ids])
      else
        @packs = @user.packs
      end
      @packs = @packs.order_by([:created_at, :desc])
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
    document = Document.find params[:id]
    filepath = document.content.path(params[:style])
    users = []
    if @user
      if @user.organization && @user.is_prescriber
        users = @user.customers
      else
        users = [@user]
      end
    end
    if File.exist?(filepath) && (document.pack.owner.in?(users) || current_user.try(:is_admin) || params[:token] == document.get_token)
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
        if @user.organization && @user.is_prescriber
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
