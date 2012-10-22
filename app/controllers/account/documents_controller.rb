# -*- encoding : UTF-8 -*-
class Account::DocumentsController < Account::AccountController
  layout :current_layout

  before_filter :load_user
  before_filter :find_last_composition, :only => %w(index)

protected
  def current_layout
    if %w(index reporting).include? params[:action]
      'inner'
    else
      nil
    end
  end

  def load_user
    if (params[:email].present? || session[:acts_as].present?) && current_user.is_admin
      @user = User.find_by_email(params[:email] || session[:acts_as]) || current_user
      if @user == current_user
        session[:acts_as] = nil
      else
        session[:acts_as] = @user.email
      end
    else
      @user = current_user
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
    raise Mongoid::Errors::DocumentNotFound.new(Pack, params[id]) unless @pack
    
    @documents = Pack.find(params[:id]).documents.without_original.asc(:position)
    document_ids = @documents.distinct(:_id)
    @all_tags = DocumentTag.any_in(:document_id => document_ids).entries

    if params[:filtre]
      contents = params[:filtre].gsub(/:_:/,' ')
      @documents = @documents.search_for(contents).asc(:position)
    end
  end
  
  def packs
    if params[:filtre]
      contents = params[:filtre].gsub(/:_:/,' ')
      @packs = Pack.any_in(user_ids: [@user.id]).search_for(contents)
    else
      @packs = Pack.any_in(user_ids: [@user.id])
    end
    @packs = @packs.order_by([:created_at, :desc])
    
    if params[:view] == "self"
      @packs = @packs.where(:owner_id => @user.id)
    elsif params[:view] != "all" and params[:view].present?
      @other_user = User.find(params[:view])
      @packs = @packs.where(:owner_id => @other_user.id)
    end
    
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
  
  def find
    query = params[:having].split(':_:')
    
    @documents = []

    document_ids = ""
    query.each_with_index do |tag,index|
      if index == 0
        DocumentTag.where(:name => /\w*#{tag}\w*/, :user_id => @user.id).each do |document_tag|
          document_ids += " #{document_tag.document_id}"
        end
      else
        document_ids_2 = document_ids
        document_ids_2.split.each do |document_id|
          if (DocumentTag.where(:document_id => document_id, :name => /\w*#{tag}\w*/).first).nil?
            document_ids = document_ids.gsub(/#{document_id}/,'')
            end
        end
      end
    end
    
    @documents = Document.any_in(:_id => document_ids.split).without_original.entries
    @documents += Document::Index.find_document(query, @user).entries
    @documents = @documents.uniq
    
    render :action => "show"
  end
    
  def archive
    pack = Pack.find(params[:pack_id])
    
    if pack.divisions.sheets.count > 0
      unless File.directory?("#{Rails.root}/public/system/archive/#{current_user.id}")
        Dir.mkdir("#{Rails.root}/public/system/archive/#{current_user.id}")
      end
      
      pack.divisions.sheets.each do |sheet|
        filename = sheet.name.gsub(/\s/,'_')
        start_number = sheet.start
        end_number = sheet.end
        
        part = (start_number == end_number) ? start_number.to_s : start_number.to_s+"-"+end_number.to_s
        
        url = "#{Rails.root}/public#{pack.documents.where(:is_an_original => true).first.content.url.sub(/\.pdf.*/,'.pdf')}"
        cmd = "pdftk A=#{url} cat A#{part} output #{Rails.root}/public/system/archive/#{current_user.id}/#{filename}.pdf"
        system(cmd)
      end
      
      new_name = pack.name.gsub(/\s/,'_')
    
      Dir.chdir("#{Rails.root}/public/system/archive/#{current_user.id}/")
      system("rm *.zip") rescue nil # suppression du précèdent zip
      system("zip '#{new_name}.zip' *.pdf")
      system("rm *.pdf")
      
      @url = "/system/archive/#{current_user.id}/#{new_name}.zip"
      
      respond_to do |format|
        format.json do
          render :json => @url.to_json, :status => :ok
        end
      end
    else
      respond_to do |format|
        format.json do
          render :json => 'Ce document ne contient aucune information de hashage'.to_json, :status => :error
        end
      end
    end
  end
  
  def historic
    if params[:email].present? and (current_user.is_admin or current_user.is_prescriber)
      @user = User.find_by_email(params[:email])
    end
    @user ||= current_user
    @pack = Pack.where(:_id => params[:id]).any_in(:user_ids => [@user.id]).first
    @events = @pack.historic
  end
  
  def sync_with_external_file_storage
    packs = []
    all_packs = Pack.any_in(:user_ids => [@user.id])
    all_pack_ids = all_packs.distinct(:_id)
    @pack_ids = []
    if params[:pack_ids].present?
      clean_pack_ids = all_pack_ids.map { |id| "#{id}" }
      @pack_ids = params[:pack_ids].select { |pack_id| clean_pack_ids.include?(pack_id) }
    elsif params[:filter].present?
      queries = params[:filter].split(':_:')
      queries.each_with_index do |query,index|
        if index == 0
          f_pack_ids = Document::Index.find_pack_ids [query], @user
          t_pack_ids = Pack.find_ids_by_tags [query], @user
          @pack_ids += f_pack_ids + t_pack_ids
        else
          f_pack_ids = Pack.any_in(:_id => pack_ids).any_in(:_id => Document::Index.find_pack_ids([query], @user)).distinct(:_id)
          t_pack_ids = Pack.any_in(:_id => pack_ids).any_in(:_id => Pack.find_ids_by_tags([query], @user)).distinct(:_id)
          @pack_ids += f_pack_ids + t_pack_ids
        end
      end
      @pack_ids = @pack_ids.uniq
    else
      @pack_ids = all_pack_ids
    end

    packs = Pack.any_in(:_id => @pack_ids)

    if params[:view].present?
      if params[:view] == "self"
        packs = packs.where(:owner_id => @user.id)
      elsif params[:view] != "all"
        other_user = User.find(params[:view])
        packs = packs.where(:owner_id => other_user.id)
      end
    end

    packs = packs.order_by([[:created_at, :desc]])
    result_pack_ids = packs.distinct(:_id)

    type = params[:type].to_i || PackDeliveryList::ALL
    
    pack_delivery_list = current_user.find_or_create_pack_delivery_list
    pack_delivery_list.add!(result_pack_ids,type)
    PackDeliveryList.delay(:queue => 'delivery', :priority => 5).process(pack_delivery_list.id)

    respond_to do |format|
      format.html{ render :nothing => true, :status => 200 }
      format.json { render :json => true, :status => :ok }
    end
  end
end
