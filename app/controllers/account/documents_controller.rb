# -*- encoding : UTF-8 -*-
class Account::DocumentsController < Account::AccountController
  layout :current_layout

  before_filter :load_user
  before_filter :find_last_composition, :only => %w(index)
  skip_before_filter :login_user!, :only => %w(download piece)

protected
  def current_layout
    if params[:action] == 'index'
      'inner'
    else
      nil
    end
  end

  def find_last_composition
    @last_composition = @user.composition
  end
  
  def load_entries
    pack_ids = @packs.map { |pack| pack.id }
    packs = Pack.any_in(:_id => pack_ids)
    @all_documents = Document.any_in(:pack_id => pack_ids).entries
    @all_original_documents = @all_documents.select{ |document| document.is_an_original }
    original_document_ids = @all_original_documents.map { |document| document.id }
    @all_tags = DocumentTag.any_in(:document_id => original_document_ids).entries
    user_ids = packs.distinct(:user_ids)
    @all_users = User.any_in(:_id => user_ids).entries
  end

public
  def index
    @packs = Pack.any_in(:user_ids => [@user.id]).desc(:created_at)
    @packs_count = @packs.count
    @packs = @packs.page(params[:page]).per(20)
    if @last_composition
      @composition = Document.any_in(:_id => @last_composition.document_ids)
    end
    load_entries
  end
  
  def show
    @pack = Pack.any_in(:user_ids => [@user.id]).distinct(:_id).select { |pack_id| pack_id.to_s == params[:id] }.first
    raise Mongoid::Errors::DocumentNotFound.new(Pack, params[:id]) unless @pack
    
    @documents = Pack.find(params[:id]).documents.without_original.asc(:position)
    document_ids = @documents.distinct(:_id)
    @all_tags = DocumentTag.any_in(:document_id => document_ids).entries

    if params[:filtre]
      contents = params[:filtre].gsub(/:_:/,' ')
      @documents = @documents.search_for(contents).asc(:position)
    end
  end
  
  def packs
    if params[:view] == "current_delivery"
      pack_ids = @user.remote_files.not_processed.distinct(:pack_id)
      @packs = @user.packs.any_in(_id: pack_ids)
      @remaining_files = @user.remote_files.not_processed.count
    else
      if params[:filtre]
        contents = params[:filtre].gsub(/:_:/,' ')
        @packs = Pack.any_in(user_ids: [@user.id]).search_for(contents)
      else
        @packs = Pack.any_in(user_ids: [@user.id])
      end

      if params[:view] == "self"
        @packs = @packs.where(:owner_id => @user.id)
      elsif params[:view] != "all" and params[:view].present?
        @other_user = User.find(params[:view])
        @packs = @packs.where(:owner_id => @other_user.id)
      end
    end

    @packs = @packs.order_by([:created_at, :desc])

    @packs_count = @packs.count
    @packs = @packs.page(params[:page]).per(params[:per_page])
    load_entries
  end

  def search
    @results = Pack.any_in(user_ids: [@user.id]).find_words(params[:q])

    respond_to do |format|
      format.json{ render json: @results.to_json, callback: params[:callback], status: :ok }
    end
  end
    
  def archive
    if current_user.is_admin
      pack = Pack.find(params[:id])
    else
      pack = Pack.any_in(user_ids: [@user.id]).where(_id: params[:id]).first
    end
    if pack
      filespath = pack.pieces.map { |e| e.content.path }
      clean_filespath = filespath.map { |e| "'#{e}'" }.join(' ')
      filename = pack.name.gsub(/\s/,'_') + '.zip'
      filepath = File.join([Rails.root,'files/attachments/archives/'+filename])
      system("zip -j #{filepath} #{clean_filespath}")
      send_file(filepath, type: 'application/zip', filename: filename, x_sendfile: true)
    else
      render nothing: true, status: 404
    end
  end
  
  def sync_with_external_file_storage
    if params[:pack_ids].present?
      @packs = Pack.any_in(user_ids: [@user.id], _id: params[:pack_ids])
    else
      @packs = @user.packs
    end
    @packs = @packs.order_by([:created_at, :desc])
    type = params[:type].to_i || Pack::ALL

    @packs.each do |pack|
      pack.init_delivery_for current_user, type, true
    end

    respond_to do |format|
      format.html { render nothing: true, status: 200 }
      format.json { render json: true, status: :ok }
    end
  end

  def download
    document = Document.find params[:id]
    filepath = document.content.path(params[:style])
    if File.exist?(filepath) && (@user && @user.in?(document.pack.users)) or params[:token] == document.get_token
      filename = File.basename(filepath)
      type = document.content_file_type || 'application/pdf'
      send_file(filepath, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  def piece
    piece = Pack::Piece.find params[:id]
    filepath = piece.content.path
    if File.exist?(filepath) && (@user && @user.in?(piece.pack.users)) || params[:token] == piece.get_token
      filename = File.basename(filepath)
      type = piece.content_file_type || 'application/pdf'
      send_file(filepath, type: type, filename: filename, x_sendfile: true)
    else
      render nothing: true, status: 404
    end
  end
end
