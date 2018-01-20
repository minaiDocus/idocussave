# -*- encoding : UTF-8 -*-
class Api::Mobile::DataLoaderController < MobileApiController
  before_filter :load_user_and_role
  before_filter :verify_suspension
  before_filter :verify_if_active
  before_filter :load_organization

  respond_to :json

  def load_customers
    render json: {customers: accounts}, status: 200
  end

  def load_packs
    packs = [search_pack, search_temp_pack, search_packs_with_error].flatten
    render json: {packs: packs}, status: 200
  end

  def load_documents_processed
    data_loaded = documents_collection
    render json: {published: data_loaded[:datas], total: data_loaded[:total], nb_pages: data_loaded[:nb_pages]}, status: 200
  end

  def load_documents_processing
    render json: {publishing: temp_documents_collection}, status: 200
  end

  def load_stats
    if verify_rights_stats
      #If rights authorized
      per_page = 20
      filters = params[:paper_process_contains]
      if filters.present?
        filters[:created_at] = {:>= => filters[:created_at_start], :<= => filters[:created_at_end]}
      end

      order_by = params[:order][:order_by] || "created_at"
      direction = params[:order][:direction]? "asc" : "desc"

      case params[:order][:order_by]
        when "type"
          order_by = "type"
        when "code"
          order_by = "customer_code"
        when "number"
          order_by = "tracking_number"
        when "packname"
          order_by = "pack_name"
        else
          order_by = "created_at"
      end

      paper_processes = PaperProcess.search_for_collection_with_options_and_user(
        PaperProcess.where(user_id: accounts),
        search_terms(filters),
        accounts
      ).order(order_by => direction).includes(:user).page(params[:page]).per(per_page)

      nb_pages = (paper_processes.total_count.to_f / per_page.to_f).ceil

      data_paper_processes = paper_processes.collect do |paper_process|
          company = "-"
          customer_code = "-"
          if @user.is_prescriber && @user.organization
            company = paper_process.user.try(:company) || "-"
            customer_code = paper_process.customer_code
          end
          
          {
            id_idocus: paper_process.id.to_s,
            date: paper_process.created_at,
            type: paper_process.type,
            company: company,
            code: customer_code,
            number: paper_process.tracking_number,
            packname: paper_process.pack_name,
          }
      end

      render json: {data_stats: data_paper_processes, nb_pages: nb_pages, total: paper_processes.total_count}, status: 200
    else
      render json: {data_stats: [], nb_pages: 1, total: 0}, status: 200
    end
  end

  def render_image_documents
    # NOTE : temporary fix
    style = params[:style] == 'thumb' ? 'medium' : params[:style].presence
    begin
      document = Document.find(params[:id])
      owner    = document.pack.owner
      filepath = document.content.path(style)
    rescue
      document = TempDocument.find(params[:id])
      owner    = document.temp_pack.user
      filepath = document.content.path(style)
    end

    if params[:force_temp_document] == 'true'
      document = TempDocument.find(params[:id])
      owner    = document.temp_pack.user
      filepath = document.content.path
    end

    if File.exist?(filepath) && (owner.in?(accounts) || current_user.try(:is_admin) || params[:token] == document.get_token)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: document.content_file_name, x_sendfile: true, disposition: 'inline')
    else
      render json: { error: true, message: 'file not found' }, status: 404
    end
  end

  def get_packs
    per_page = 20

    options = {page: params[:page], per_page: per_page}
    options[:sort] = true unless params[:filter].present?
    options[:owner_ids] = if params[:view].present? && params[:view] != 'all'
      _user = accounts.find(params[:view])
      _user ? [_user.id] : []
    else
      account_ids
    end

    packs = Pack.search(params[:filter], options)
    nb_pages = (packs.total_count.to_f / per_page.to_f).ceil

    loaded_packs = packs.inject([]) do |memo, pack|
      memo += [{  id: pack.id, 
                  name: pack.name.sub(' all', ''), 
                  created_at: pack.created_at, 
                  updated_at: pack.updated_at, 
                  owner_id: pack.owner_id
              }]
    end

    render json: {packs: loaded_packs, nb_pages: nb_pages, total: packs.total_count}, status:200
  end

  private

  def verify_rights_stats
    unless accounts.detect { |e| e.options.is_upload_authorized }
      return false
    end
    return true
  end

  def search_pack
    packs = all_packs.order(updated_at: :desc).limit(5)
    loaded = packs.inject([]) do |memo, pack|
      memo += [{  id: pack.id,
                  pack_id: pack.id, 
                  name: pack.name.sub(' all', ''), 
                  created_at: pack.created_at, 
                  updated_at: pack.updated_at, 
                  owner_id: pack.owner_id, 
                  page_number: 0,
                  message: "",
                  type: "pack"
                }]
    end
  end

  def search_temp_pack
    temp_packs = @user.temp_packs.not_published.order(updated_at: :desc).limit(5)

    loaded = temp_packs.inject([]) do |memo, tmp_pack|
      memo += [{  id: tmp_pack.id,
                  pack_id: get_pack_from_temp_pack(tmp_pack), 
                  name: tmp_pack.basename,
                  created_at: tmp_pack.created_at,
                  updated_at: tmp_pack.updated_at,
                  owner_id: tmp_pack.user_id,
                  page_number: tmp_pack.temp_documents.not_published.sum(:pages_number).to_i,
                  message: "",
                  type: "temp_pack"
                }]
    end
  end

  def search_packs_with_error
    if @user.is_prescriber && @user.organization.try(:ibiza).try(:configured?)
      customers = @user.is_admin ? @user.organization.customers : @user.customers
      errors = Pack::Report.failed_delivery(customers.pluck(:id), 5)
      loaded = errors.each_with_index.inject([]) do |memo, (err, index)|
        memo += [{  id: (500+index),
                    pack_id: 0, 
                    name: err.name,
                    created_at: err.date,
                    updated_at: err.date,
                    owner_id: 0,
                    page_number: err.document_count,
                    message: err.message == false ? '-' : err.message,
                    type: "error"
                }]
      end
    end
    loaded || []
  end

  def documents_collection
    per_page = 30
    documents = Document.search(params[:filter],
      pack_id:  params[:id],
      page:params[:page],
      per_page: per_page,
      sort:     true
    ).where.not(origin: ['mixed']).order(position: :asc).includes(:pack)

    nb_pages = (documents.total_count.to_f / per_page.to_f).ceil

    data_collected = documents.collect do |document|
        if document.mongo_id
          id_doc = document.mongo_id
          filepath = "#{Rails.root}/files/#{Rails.env}/#{document.class.table_name}/contents/#{document.mongo_id}/thumb/#{document.content_file_name.gsub('pdf', 'png')}"
        else
          id_doc = document.id
          filepath = "#{Rails.root}/files/#{Rails.env}/#{document.class.table_name}/contents/#{document.id}/thumb/#{document.content_file_name.gsub('pdf', 'png')}"
        end

        unless document.dirty || !File.exist?(filepath)
          thumb = {id:id_doc, style:'thumb', filter: document.content_file_name}
          large = {id:id_doc, style:'original', filter: document.content_file_name}
        else
          thumb = large = false
        end

        {
          id: document.id,
          thumb: thumb,
          large: large
        }
    end

    {datas: data_collected, nb_pages: nb_pages, total: documents.total_count}
  end

  def temp_documents_collection
    @pack = Pack.where(owner_id: account_ids, id: params[:id]).first!
    temp_documents = []

    unless @pack.is_fully_processed || params[:filter].presence
      temp_pack      = TempPack.find_by_name(@pack.name)
      temp_documents = temp_pack.temp_documents.not_published
    end

    temp_documents.collect do |temp_document|
      if temp_document.mongo_id
        id_doc = temp_document.mongo_id
        filepath = "#{Rails.root}/files/#{Rails.env}/#{temp_document.class.table_name}/contents/#{temp_document.mongo_id}/thumb/#{temp_document.content_file_name}"
      else
        id_doc = temp_document.id
        filepath = "#{Rails.root}/files/#{Rails.env}/#{temp_document.class.table_name}/contents/#{temp_document.id}/thumb/#{temp_document.content_file_name}"
      end

      unless !File.exist?(filepath)
        thumb = {id:id_doc, style:'thumb', filter: temp_document.content_file_name}
      else
        thumb = false
      end

      {
        id: temp_document.id,
        thumb: thumb,
        large: {id:id_doc, style:'large', filter: temp_document.content_file_name}
      }
    end
  end

  def get_pack_from_temp_pack(tmp_pack)
      pack = Pack.find_by_name(tmp_pack.name)
      pack_id = 0
      pack_id = pack.id if pack.present?
  end
end