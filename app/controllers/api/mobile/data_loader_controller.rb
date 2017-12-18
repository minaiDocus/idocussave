# -*- encoding : UTF-8 -*-
class Api::Mobile::DataLoaderController < MobileApiController
  before_filter :load_user_and_role
  before_filter :verify_suspension
  before_filter :verify_if_active
  before_filter :load_organization

  respond_to :json

  def load_customers
    render json: {customers: customers}, status: 200
  end

  def load_packs
    packs = [search_pack, search_temp_pack, search_packs_with_error].flatten
    render json: {packs: packs}, status: 200
  end

  def load_packs_documents
    @pack = Pack.where(owner_id: account_ids, id: params[:id]).first!

   render json: {published: documents_collection, publishing: temp_documents_collection}, status: 200
  end

  def load_stats
    filters = params[:paper_process_contains]
    if filters.present?
      filters[:updated_at] = {:>= => filters[:updated_at_start], :<= => filters[:updated_at_end]}
    end

     paper_processes = PaperProcess.search_for_collection_with_options_and_user(
      PaperProcess.where(user_id: accounts),
      search_terms(filters),
      accounts
    ).order("created_at" => "desc").includes(:user).page(1).per(100)

    data_paper_processes = paper_processes.collect do |paper_process|
        {
          date: paper_process.created_at,
          type: paper_process.type,
          company: paper_process.user.try(:company),
          code: paper_process.customer_code,
          number: paper_process.tracking_number,
          packname: paper_process.pack_name,
        }
    end

    data_paper_processes = [
                              {date:"18-12-2017", type:1, code:123, company:"Mycomp", number:12, packname:"test 1"},
                              {date:"19-12-2017", type:2, code:1234, company:"12345", number:11, packname:"test 2"},
                              {date:"20-08-2017", type:3, code:12, company:"Hiscomp", number:122, packname:"test 3"},
                              {date:"18-04-2017", type:3, code:1123, company:"Thecomp", number:112, packname:"test 4"},
                              {date:"21-05-2017", type:2, code:234, company:"Hercomp", number:112, packname:"test 5"},
                              {date:"22-11-2017", type:1, code:321, company:"Comp", number:112, packname:"test 6"},
                            ]

     render json: {data_stats: data_paper_processes}, status: 200
  end

  def render_image_documents
    begin
      document = params[:id].size > 20 ? Document.find_by_mongo_id(params[:id]) : Document.find(params[:id])
      owner    = document.pack.owner
      filepath = FileStoragePathUtils.path_for_object(document, (params[:style].presence || 'original'))

      if params[:style] == 'thumb' || params[:style] == 'large'
        filepath = filepath.gsub('pdf', 'png')
      end
    rescue
      document = params[:id].size > 20 ? TempDocument.find_by_mongo_id(params[:id]) : TempDocument.find(params[:id])
      owner    = document.temp_pack.user
      filepath = FileStoragePathUtils.path_for_object(document)
    end

    if params[:force_temp_document] && params[:force_temp_document] == 'true'
      document = params[:id].size > 20 ? TempDocument.find_by_mongo_id(params[:id]) : TempDocument.find(params[:id])
      owner    = document.temp_pack.user
      filepath = FileStoragePathUtils.path_for_object(document)
    end

    if File.exist?(filepath) && (owner.in?(accounts) || current_user.try(:is_admin) || params[:token] == document.get_token)
      filename  = File.basename(filepath)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render json: {error: true, message: "file not found"}, status: 404
    end
  end


  def filter_packs()
      options = { page: params[:page], per_page: 100 }
      options[:sort] = true unless params[:filter].present?

      options[:owner_ids] = if params[:view].present? && params[:view] != 'all'
        _user = accounts.find(params[:view])
        _user ? [_user.id] : []
      else
        account_ids
      end

      packs = Pack.search(params[:filter], options)

      render json: {packs: packs.collect do |p| p.id end }, status:200
  end



  private

  def search_pack
    packs = all_packs.order(updated_at: :desc).limit(100)
    loaded = packs.inject([]) do |memo, pack|
      memo += [{  id: pack.id, 
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
    # loaded = [{ id: 200, 
    #             name: 'test erreur idocus',
    #             created_at: DateTime.now,
    #             updated_at: DateTime.now,
    #             owner_id: 0,
    #             page_number: 3,
    #             error_message: "teste error messageteste error messageteste error messageteste error messageteste error messageteste error message",
    #             type: "error"
    #           },
    #           { id: 201, 
    #             name: 'test erreur idocus2',
    #             created_at: DateTime.now,
    #             updated_at: DateTime.now,
    #             owner_id: 0,
    #             page_number: 5,
    #             error_message: "teste error messageteste error messageteste error messageteste error messageteste error messageteste error message",
    #             type: "error"
    #           }
    #         ]
    if @user.is_prescriber && @user.organization.try(:ibiza).try(:is_configured?)
      errors = Pack::Report.failed_delivery(customers.pluck(:id), 5)
      loaded = errors.each_with_index.inject([]) do |memo, (err, index)|
        memo += [{  id: (500+index), 
                    name: err.name,
                    created_at: err.date,
                    updated_at: err.date,
                    owner_id: 0,
                    page_number: err.document_count,
                    error_message: err.message == false ? '-' : err.message,
                    type: "error"
                }]
      end
    end
    loaded || []
  end

  def documents_collection
    documents = Document.search(params[:filter],
      pack_id:  params[:id],
      per_page: 10_000,
      sort:     true
    ).where.not(origin: ['mixed']).order(position: :asc).includes(:pack)

    documents.collect do |document|
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
  end

  def temp_documents_collection
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
end