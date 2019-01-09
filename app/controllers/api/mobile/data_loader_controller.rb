class Api::Mobile::DataLoaderController < MobileApiController
  respond_to :json

  def load_user_organizations
    organizations = @user.collaborator? ? @user.organizations : [@user.organization]
    render json: { organizations: organizations }, status: 200
  end

  def load_customers
    render json: { customers: accounts }, status: 200
  end

  def load_packs
    packs = [search_pack, search_temp_pack, search_packs_with_error].flatten
    render json: { packs: packs }, status: 200
  end

  def load_documents_processed
    data_loaded = documents_collection
    render json: { published: data_loaded[:datas], total: data_loaded[:total], nb_pages: data_loaded[:nb_pages] }, status: 200
  end

  def load_documents_processing
    data_loaded = temp_documents_collection
    render json: { publishing: data_loaded[:datas], total: data_loaded[:total], nb_pages: data_loaded[:nb_pages] }, status: 200
  end

  def load_stats
    if verify_rights_stats
      filters = params[:paper_process_contains]
      if filters.present?
        filters[:created_at] = { :>= => filters[:created_at_start], :<= => filters[:created_at_end] }
      end

      direction = params[:order][:direction] ? 'asc' : 'desc'

      case params[:order][:order_by]
      when 'type'
        order_by = 'type'
      when 'code'
        order_by = 'customer_code'
      when 'number'
        order_by = 'tracking_number'
      when 'packname'
        order_by = 'pack_name'
      else
        order_by = 'created_at'
      end

      paper_processes = PaperProcess.where(user_id: accounts).
        search(search_terms(filters)).
        includes(:user).
        order(order_by => direction).
        page(params[:page]).
        per(20)

      data_paper_processes = paper_processes.collect do |paper_process|
          company = customer_code = '-'

          if @user.is_prescriber && @user.organization
            company = paper_process.user.try(:company) || '-'
            customer_code = paper_process.customer_code
          end

          {
            id_idocus: paper_process.id.to_s,
            date:      paper_process.created_at,
            type:      paper_process.type,
            company:   company,
            code:      customer_code,
            number:    paper_process.tracking_number,
            packname:  paper_process.pack_name,
          }
      end

      render json: { data_stats: data_paper_processes, nb_pages: paper_processes.total_pages, total: paper_processes.total_count }, status: 200
    else
      render json: { data_stats: [], nb_pages: 1, total: 0 }, status: 200
    end
  end

  def render_image_documents
    style = params[:style].presence || 'medium'
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
    options = { page: params[:page], per_page: 20 }
    options[:sort] = true unless params[:filter].present?
    options[:owner_ids] = if params[:view].present? && params[:view] != 'all'
      _user = accounts.find(params[:view])
      _user ? [_user.id] : []
    else
      account_ids
    end

    packs = Pack.search(params[:filter], options)

    loaded_packs = packs.map do |pack|
      {
        id:         pack.id,
        name:       pack.name.sub(' all', ''),
        created_at: pack.created_at,
        updated_at: pack.updated_at,
        owner_id:   pack.owner_id
      }
    end

    render json: { packs: loaded_packs, nb_pages: packs.total_pages, total: packs.total_count }, status:200
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

    loaded = packs.map do |pack|
      {
        id:          pack.id,
        pack_id:     pack.id,
        name:        pack.name.sub(' all', ''),
        created_at:  pack.created_at,
        updated_at:  pack.updated_at,
        owner_id:    pack.owner_id,
        page_number: 0,
        message:     '',
        type:        'pack'
      }
    end
  end

  def search_temp_pack
    temp_packs = @user.temp_packs.not_published.order(updated_at: :desc).limit(5)

    loaded = temp_packs.map do |tmp_pack|
      {
        id:          tmp_pack.id,
        pack_id:     Pack.find_by_name(tmp_pack.name).try(:id) || 0,
        name:        tmp_pack.basename,
        created_at:  tmp_pack.created_at,
        updated_at:  tmp_pack.updated_at,
        owner_id:    tmp_pack.user_id,
        page_number: tmp_pack.temp_documents.not_published.sum(:pages_number).to_i,
        message:     '',
        type:        'temp_pack'
      }
    end
  end

  def search_packs_with_error
    if @user.is_prescriber
      customers = @user.is_admin ? @user.organization.customers : @user.customers
      errors = Pack::Report.failed_delivery(customers.pluck(:id), 5)
      loaded = errors.each_with_index.map do |err, index|
        {
          id:          (500+index),
          pack_id:     0,
          name:        err.name,
          created_at:  err.date,
          updated_at:  err.date,
          owner_id:    0,
          page_number: err.document_count,
          message:     err.message == false ? '-' : err.message.gsub('<br>', "\n"),
          type:        'error'
        }
      end
    end
    loaded || []
  end

  def documents_collection
    documents = Document.search(params[:filter],
      pack_id:  params[:id],
      page:     params[:page],
      per_page: 20,
      sort:     true
    ).not_mixed.order(position: :asc).includes(:pack)

    data_collected = documents.collect do |document|
        if File.exist?(document.content.path(:medium))
          thumb = { id: document.id, style: 'medium',   filter: document.content_file_name }
          large = { id: document.id, style: 'original', filter: document.content_file_name }
        else
          thumb = large = false
        end

        {
          id:    document.id,
          thumb: thumb,
          large: large
        }
    end

    { datas: data_collected, nb_pages: documents.total_pages, total: documents.total_count }
  end

  def temp_documents_collection
    @pack = Pack.where(owner_id: account_ids, id: params[:id]).first!
    temp_documents = []

    unless @pack.is_fully_processed || params[:filter].presence
      temp_pack      = TempPack.find_by_name(@pack.name)
      temp_documents = temp_pack.temp_documents.not_published.page(params[:page] || 1).per(20)
    end

    data_collected = temp_documents.collect do |temp_document|
      if File.exist?(temp_document.content.path(:medium))
        thumb = { id: temp_document.id, style: 'medium', filter: temp_document.content_file_name }
      else
        thumb = false
      end

      {
        id:    temp_document.id,
        thumb: thumb,
        large: { id: temp_document.id, style: 'large', filter: temp_document.content_file_name }
      }
    end

    { datas: data_collected, nb_pages: temp_documents.try(:total_pages) || 0, total: temp_documents.try(:total_count) || 0 }
  end
end
