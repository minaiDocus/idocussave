# -*- encoding : UTF-8 -*-
class Account::DocumentsController < Account::AccountController
  layout :current_layout

  skip_before_filter :login_user!, :only => %w(download piece)
  before_filter :load_user_and_role
  before_filter :find_last_composition, :only => %w(index)

protected
  def current_layout
    action_name == 'index' ? 'inner' : nil
  end

  def find_last_composition
    @last_composition = @user.composition
  end

public
  def index
    options = {}
    if @user.is_prescriber
      owner_ids = [@user.id.to_s] + @user.customer_ids.map(&:to_s)
      options = { owner_ids: owner_ids }
    else
      pack_ids = @user.packs.distinct(:_id).map(&:to_s)
      if pack_ids.any?
        options = { ids: pack_ids }
      else
        options = { owner_id: @user.id }
      end
    end
    @packs = Pack.search(params[:filter], { page: params[:page] || 1, per_page: params[:per_page] || 20 }.merge(options))
    @packs_count = @packs.total
    
    @composition = Document.any_in(:_id => @last_composition.document_ids) if @last_composition
  end
  
  def show
    id = BSON::ObjectId.from_string(params[:id])
    if @user.organization && @user.is_prescriber
      pack_ids = @user.packs.distinct(:_id)
    else
      pack_ids = @user.pack_ids
    end
    raise Mongoid::Errors::DocumentNotFound.new(Pack, params[:id]) unless id.in?(pack_ids)
    @pack = Pack.find(params[:id])
    @documents = Document.search(params[:filter], pack_id: params[:id], is_an_original: false, per_page: 10000)
  end

  def packs
    if params[:view] == "current_delivery"
      pack_ids = @user.remote_files.not_processed.distinct(:pack_id)
      @packs = @user.packs.any_in(_id: pack_ids)
      @remaining_files = @user.remote_files.not_processed.count
      @packs_count = @packs.count
      @packs = @packs.page(params[:page]).per(params[:per_page])
    else
      options = {}
      owner_ids = []
      if @user.is_prescriber
        if params[:view].present? && params[:view] != 'all'
          if params[:view] == 'self'
            @other_user = @user
          else
            @other_user = @user.customers.find(params[:view])
          end
          owner_ids = [@other_user.id.to_s] if @other_user
        else
          owner_ids = [@user.id.to_s] + @user.customer_ids.map(&:to_s)
        end
        @packs = Pack.search(params[:filter], owner_ids: owner_ids, page: params[:page], per_page: params[:per_page])
      else
        if params[:view].present? && params[:view] != 'all'
          if params[:view] == 'self'
            @other_user = @user
          else
            @other_user = User.find(params[:view])
          end
          owner_id = @other_user.id.to_s
          pack_ids = @user.packs.distinct(:_id).map(&:to_s)
          @packs = Pack.search(params[:filter], ids: pack_ids, owner_id: owner_id, page: params[:page], per_page: params[:per_page])
        else
          pack_ids = @user.packs.distinct(:_id).map(&:to_s)
          @packs = Pack.search(params[:filter], ids: pack_ids, page: params[:page], per_page: params[:per_page])
        end
      end
      @packs_count = @packs.total
    end
  end
    
  def archive
    id = BSON::ObjectId.from_string(params[:id])
    if @user.organization && @user.is_prescriber
      pack_ids = @user.packs.distinct(:_id)
    else
      pack_ids = @user.pack_ids
    end
    raise Mongoid::Errors::DocumentNotFound.new(Pack, params[:id]) unless id.in?(pack_ids)
    pack = Pack.find(params[:id])

    filespath = pack.pieces.map { |e| e.content.path }
    clean_filespath = filespath.map { |e| "'#{e}'" }.join(' ')
    filename = pack.name.gsub(/\s/,'_') + '.zip'
    filepath = File.join([Rails.root,'files/attachments/archives/'+filename])
    system("zip -j #{filepath} #{clean_filespath}")
    send_file(filepath, type: 'application/zip', filename: filename, x_sendfile: true)
  end
  
  def sync_with_external_file_storage
    if current_user.is_admin
      if params[:pack_ids].present?
        @packs = Pack.any_in(user_ids: [@user.id], _id: params[:pack_ids])
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
    if File.exist?(filepath) && ((@user && @user.packs.distinct(:_id).include?(document.pack.id)) || (current_user && current_user.is_admin) || params[:token] == document.get_token)
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
    piece = Pack::Piece.find params[:id]
    filepath = piece.content.path
    if File.exist?(filepath) && ((@user && @user.packs.distinct(:_id).include?(piece.pack.id)) || (current_user && current_user.is_admin) || params[:token] == piece.get_token)
      filename = File.basename(filepath)
      type = piece.content_file_type || 'application/pdf'
      send_file(filepath, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end
end
