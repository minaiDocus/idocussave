# frozen_string_literal: true

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

  def load_preseizures
    data_loaded = preseizures_collection
    render json: { preseizures: data_loaded[:datas], total: data_loaded[:total], nb_pages: data_loaded[:nb_pages] }, status: 200
  end

  def load_stats
    if verify_rights_stats
      filters = params[:paper_process_contains]
      if filters.present?
        filters[:created_at] = { :>= => filters[:created_at_start], :<= => filters[:created_at_end] }
      end

      direction = params[:order][:direction] ? 'asc' : 'desc'

      order_by = case params[:order][:order_by]
                 when 'type'
                   'type'
                 when 'code'
                   'customer_code'
                 when 'number'
                   'tracking_number'
                 when 'packname'
                   'pack_name'
                 else
                   'created_at'
                 end

      paper_processes = PaperProcess.where(user_id: accounts)
                                    .search(search_terms(filters))
                                    .includes(:user)
                                    .order(order_by => direction)
                                    .page(params[:page])
                                    .per(20)

      data_paper_processes = paper_processes.collect do |paper_process|
        company = customer_code = '-'

        if @user.is_prescriber && @user.organization
          company = paper_process.user.try(:company) || '-'
          customer_code = paper_process.customer_code
        end

        {
          id_idocus: paper_process.id.to_s,
          date: paper_process.created_at,
          type: paper_process.type,
          company: company,
          code: customer_code,
          number: paper_process.tracking_number,
          packname: paper_process.pack_name
        }
      end

      render json: { data_stats: data_paper_processes, nb_pages: paper_processes.total_pages, total: paper_processes.total_count }, status: 200
    else
      render json: { data_stats: [], nb_pages: 1, total: 0 }, status: 200
    end
  end

  def render_image_documents
    style = params[:style].presence || 'medium'

    if params[:force_temp_document] == 'true'
      document = TempDocument.find(params[:id])
      owner    = document.temp_pack.user
      filepath = document.cloud_content_object.path(style)
    else
      begin
        document = Pack::Piece.find(params[:id])
        owner    = document.user
        filepath = document.cloud_content_object.path(style)
      rescue StandardError
        document = TempDocument.find(params[:id])
        owner    = document.temp_pack.user
        filepath = document.cloud_content_object.path(style)
      end
    end

    if File.exist?(filepath.to_s) && (owner.in?(accounts) || current_user.try(:is_admin) || params[:token] == document.get_token)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: document.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render json: { error: true, message: 'file not found' }, status: 404
    end
  end

  def get_packs
    filter = params[:filter]

    if filter[:by_all].present?
      filter[:by_piece] = filter[:by_piece].present? ? filter[:by_piece].merge(filter[:by_all]) : filter[:by_all]
      filter[:by_preseizure] = filter[:by_preseizure].present? ? filter[:by_preseizure].merge(filter[:by_all]) : filter[:by_all]
    end

    options = { page: params[:page], per_page: 20 }
    options[:sort] = true

    options[:piece_created_at] = filter[:by_piece].try(:[], :created_at)
    options[:piece_created_at_operation] = filter[:by_piece].try(:[], :created_at_operation)

    options[:piece_position] = filter[:by_piece].try(:[], :position)
    options[:piece_position_operation] = filter[:by_piece].try(:[], :position_operation)

    options[:name] = filter[:by_pack].try(:[], :pack_name)
    options[:tags] = filter[:by_piece].try(:[], :tags)

    options[:owner_ids] = if params[:view].present? && params[:view] != 'all'
                            _user = accounts.find(params[:view])
                            _user ? [_user.id] : []
                          else
                            account_ids
    end

    if filter[:by_preseizure].present?
      piece_ids = Pack::Report::Preseizure.where(user_id: options[:owner_ids], operation_id: ['', nil]).filter_by(filter[:by_preseizure]).distinct.pluck(:piece_id).presence || [0]
    end

    options[:piece_ids] = piece_ids if piece_ids.present?

    packs = Pack.search(filter.try(:[], :by_piece).try(:[], :content), options).distinct.order(updated_at: :desc).page(options[:page]).per(options[:per_page])

    loaded_packs = packs.map do |pack|
      software = get_software_info pack.user
      preseizures_infos = get_preseizures_infos pack

      {
        # pack infos
        id: pack.id,
        type: 'pack',
        name: pack.name.sub(' all', ''),
        created_at: pack.created_at,
        updated_at: pack.updated_at,
        owner_id: pack.owner_id,
        # preseizure infos
        is_delivered: !pack.reports.select { |r| r.is_delivered? }.empty?,
        first_preseizure_created_at: preseizures_infos.try(:min_created_at),
        last_preseizure_created_at: preseizures_infos.try(:max_created_at),
        last_delivery_tried_at: preseizures_infos.try(:max_delivery_tried_at),
        last_delivery_message: pack.get_delivery_message_of(software[:name]).to_s,
        software_name: software[:name],
        software_human_name: software[:human_name]
      }
    end

    render json: { packs: loaded_packs, nb_pages: packs.total_pages, total: packs.total_count }, status: 200
  end

  def get_reports
    filter = params[:filter]
    options = {}
    options[:user_ids] = if params[:view].present? && params[:view] != 'all'
                           _user = accounts.find(params[:view])
                           _user ? [_user.id] : []
                         else
                           account_ids
    end

    if filter[:by_all].present?
      filter[:by_preseizure] = filter[:by_preseizure].present? ? filter[:by_preseizure].merge(filter[:by_all]) : filter[:by_all]
    end

    options[:name] = filter[:by_pack].try(:[], :pack_name)

    if filter[:by_preseizure].present?
      reports_ids = Pack::Report::Preseizure.where(user_id: options[:user_ids]).where('operation_id > 0').filter_by(filter[:by_preseizure]).distinct.pluck(:report_id).presence || [0]
    end
    options[:ids] = reports_ids if reports_ids.present?

    reports = Pack::Report.preseizures.joins(:preseizures).where(pack_id: nil).search(options).distinct.order(updated_at: :desc).page(params[:page] || 1).per(20)

    loaded_reports = reports.map do |report|
      software = get_software_info report.user
      preseizures_infos = get_preseizures_infos report

      {
        # report infos
        id: report.id,
        type: 'report',
        name: report.name.sub('all', '').strip,
        created_at: report.created_at,
        updated_at: report.updated_at,
        owner_id: report.user_id,
        # Preseizure infos
        is_delivered: report.is_delivered?,
        first_preseizure_created_at: preseizures_infos.try(:min_created_at),
        last_preseizure_created_at: preseizures_infos.try(:max_created_at),
        last_delivery_tried_at: preseizures_infos.try(:max_delivery_tried_at),
        last_delivery_message: report.get_delivery_message_of(software[:name]).to_s,
        software_name: software[:name],
        software_human_name: software[:human_name]
      }
    end

    render json: { reports: loaded_reports, nb_pages: reports.total_pages, total: reports.total_count }, status: 200
  end

  private

  def verify_rights_stats
    return false unless accounts.detect { |e| e.options.is_upload_authorized }

    true
  end

  def search_pack
    packs = all_packs.order(updated_at: :desc).limit(5)

    loaded = packs.map do |pack|
      software = get_software_info pack.user
      preseizures_infos = get_preseizures_infos pack

      {
        id: pack.id,
        pack_id: pack.id,
        name: pack.name.sub('all', '').strip,
        created_at: pack.created_at,
        updated_at: pack.updated_at,
        owner_id: pack.owner_id,
        page_number: 0,
        message: '',
        type: 'pack',
        # Preseizure infos
        is_delivered: !pack.reports.select { |r| r.is_delivered? }.empty?,
        first_preseizure_created_at: preseizures_infos.try(:min_created_at),
        last_preseizure_created_at: preseizures_infos.try(:max_created_at),
        last_delivery_tried_at: preseizures_infos.try(:max_delivery_tried_at),
        last_delivery_message: pack.get_delivery_message_of(software[:name]).to_s,
        software_name: software[:name],
        software_human_name: software[:human_name]
      }
    end
  end

  def search_temp_pack
    temp_packs = @user.temp_packs.not_published.order(updated_at: :desc).limit(5)

    loaded = temp_packs.map do |tmp_pack|
      pack = Pack.find_by_name(tmp_pack.name)
      software = get_software_info tmp_pack.user
      preseizures_infos = pack ? get_preseizures_infos(pack) : nil

      {
        id: tmp_pack.id,
        pack_id: pack.try(:id) || 0,
        name: tmp_pack.basename,
        created_at: tmp_pack.created_at,
        updated_at: tmp_pack.updated_at,
        owner_id: tmp_pack.user_id,
        page_number: tmp_pack.temp_documents.not_published.sum(:pages_number).to_i,
        message: '',
        type: 'temp_pack',
        # Preseizure infos
        is_delivered: pack ? !pack.reports.select { |r| r.is_delivered? }.empty? : true,
        first_preseizure_created_at: preseizures_infos.try(:min_created_at),
        last_preseizure_created_at: preseizures_infos.try(:max_created_at),
        last_delivery_tried_at: preseizures_infos.try(:max_delivery_tried_at),
        last_delivery_message: pack ? pack.get_delivery_message_of(software[:name]).to_s : nil,
        software_name: software[:name],
        software_human_name: software[:human_name]
      }
    end
  end

  def search_packs_with_error
    if @user.is_prescriber
      customers = @user.is_admin ? @user.organization.customers : @user.customers
      errors = Pack::Report.failed_delivery(customers.pluck(:id), 5)
      loaded = errors.each_with_index.map do |err, index|
        {
          id: (500 + index),
          pack_id: 0,
          name: err.name,
          created_at: err.date,
          updated_at: err.date,
          owner_id: 0,
          page_number: err.document_count,
          message: err.message == false ? '-' : err.message.gsub('<br>', "\n"),
          type: 'error'
        }
      end
    end
    loaded || []
  end

  def documents_collection
    filter = params[:filter]

    pack = Pack.where(id: params[:id]).first!

    if filter[:by_all].present?
      filter[:by_piece] = filter[:by_piece].present? ? filter[:by_piece].merge(filter[:by_all]) : filter[:by_all]
      filter[:by_preseizure] = filter[:by_preseizure].present? ? filter[:by_preseizure].merge(filter[:by_all]) : filter[:by_all]
    end

    if filter[:by_preseizure].present?
      piece_ids = pack.preseizures.filter_by(filter[:by_preseizure]).distinct.pluck(:piece_id).presence || [0]
    end

    documents = pack.pieces

    documents = documents.where(id: piece_ids) if piece_ids.present?
    if filter[:by_piece].try(:[], :content)
      documents = documents.where('pack_pieces.name LIKE ? OR pack_pieces.tags LIKE ? OR pack_pieces.content_text LIKE ?', "%#{filter[:by_piece][:content]}%", "%#{filter[:by_piece][:content]}%", "%#{filter[:by_piece][:content]}%")
    end
    if filter[:by_piece].try(:[], :created_at)
      documents = documents.where("DATE_FORMAT(created_at, '%Y-%m-%d') #{filter[:by_piece][:created_at_operation].tr('012', ' ><')}= ?", filter[:by_piece][:created_at])
    end
    if filter[:by_piece].try(:[], :position)
      documents = documents.where("position #{filter[:by_piece][:position_operation].tr('012', ' ><')}= ?", filter[:by_piece][:position])
    end
    if filter[:by_piece].try(:[], :tags)
      documents = documents.where('tags LIKE ?', "%#{filter[:by_piece][:tags]}%")
    end

    documents = documents.order(position: :desc).includes(:pack).page(params[:page]).per(20)

    data_collected = documents.collect do |document|
      thumb = File.exist?(document.cloud_content_object.path(:medium).to_s) ? { id: document.id, style: 'medium', filter: document.cloud_content_object.filename } : false

      {
        id: document.id,
        thumb: thumb,
        large: { id: document.id, style: 'original', filter: document.cloud_content_object.filename },
        position: document.position,
        state: document.get_state_to(:text),
        actionOnSelect: document.user.uses_ibiza_analytics? ? 'ibiza_analytics' : ''
      }
    end

    { datas: data_collected, nb_pages: documents.try(:total_pages).to_i, total: documents.try(:total_count).to_i }
  end

  def temp_documents_collection
    @pack = Pack.where(id: params[:id]).first!
    temp_documents = []

    unless @pack.is_fully_processed || params[:filter].presence
      temp_pack      = TempPack.find_by_name(@pack.name)
      temp_documents = temp_pack.temp_documents.not_published.page(params[:page] || 1).per(20)
    end

    data_collected = temp_documents.collect do |temp_document|
      thumb = File.exist?(temp_document.cloud_content_object.path(:medium).to_s) ? { id: temp_document.id, style: 'medium', filter: temp_document.cloud_content_object.filename } : false

      {
        id: temp_document.id,
        thumb: thumb,
        large: { id: temp_document.id, style: 'original', filter: temp_document.cloud_content_object.filename },
        position: '',
        state: 'none',
        actionOnSelect: ''
      }
    end

    { datas: data_collected, nb_pages: temp_documents.try(:total_pages).to_i, total: temp_documents.try(:total_count).to_i }
  end

  def preseizures_collection
    filter = params[:filter]

    source = if params[:type] == 'pack'
               Pack.where(id: params[:id]).first!
             else
               Pack::Report.where(id: params[:id]).first!
             end

    if filter[:by_piece].present? && params[:type] == 'pack'
      pieces = source.pieces
      if filter[:by_piece].try(:[], :content)
        pieces = pieces.where('pack_pieces.name LIKE ? OR pack_pieces.tags LIKE ? OR pack_pieces.content_text LIKE ?', "%#{filter[:by_piece][:content]}%", "%#{filter[:by_piece][:content]}%", "%#{filter[:by_piece][:content]}%")
      end
      if filter[:by_piece].try(:[], :created_at)
        pieces = pieces.where("DATE_FORMAT(created_at, '%Y-%m-%d') #{filter[:by_piece][:created_at_operation].tr('012', ' ><')}= ?", filter[:by_piece][:created_at])
      end
      if filter[:by_piece].try(:[], :position)
        pieces = pieces.where("position #{filter[:by_piece][:position_operation].tr('012', ' ><')}= ?", filter[:by_piece][:position])
      end
      if filter[:by_piece].try(:[], :tags)
        pieces = pieces.where('tags LIKE ?', "%#{filter[:by_piece][:tags]}%")
      end
      piece_ids = pieces.distinct.pluck(:id).presence || [0]
    end

    preseizures = source.preseizures

    preseizures = preseizures.where(piece_id: piece_ids) if piece_ids.present?

    preseizures = preseizures.filter_by(filter[:by_preseizure]).order(position: :desc).distinct.page(params[:page]).per(15)

    data_collected = preseizures.collect do |preseizure|
      software =  get_software_info preseizure.user

      piece = preseizure.piece
      thumb = false
      large = false
      if piece
        thumb = File.exist?(piece.cloud_content_object.path(:medium).to_s) ? { id: piece.id, style: 'medium', filter: piece.cloud_content_object.filename } : false
        large = { id: piece.id, style: 'original', filter: piece.cloud_content_object.filename }
      end

      name = preseizure.piece_name
      if ibiza = preseizure.try(:organization).try(:ibiza)
        name = IbizaLib::Api::Utils.description(preseizure, ibiza.description, ibiza.description_separator) || preseizure.piece_name
      end

      {
        id: preseizure.id,
        thumb: thumb,
        large: large,
        name: name,
        position: preseizure.position,
        state: preseizure.get_state_to(:text),
        software_name: software[:name],
        software_human_name: software[:human_name],
        is_delivered: preseizure.is_delivered?,
        error_message: preseizure.get_delivery_message_of(software[:name]),
        date: preseizure.date,
        deadline_date: preseizure.deadline_date,
        created_at: preseizure.created_at,
        updated_at: preseizure.updated_at,
        delivery_tried_at: preseizure.delivery_tried_at,
        actionOnSelect: 'edition'
      }
    end

    { datas: data_collected, nb_pages: preseizures.try(:total_pages).to_i, total: preseizures.try(:total_count).to_i }
  end

  def get_software_info(user)
    software = if user.try(:uses?, :ibiza)
                 { human_name: 'Ibiza', name: 'ibiza' }
               elsif user.try(:uses?, :exact_online)
                 { human_name: 'Exact Online', name: 'exact_online' }
               else
                 { human_name: '', name: '' }
                end
    software
  end

  def get_preseizures_infos(pack_or_report)
    pack_or_report.preseizures.select('MIN(pack_report_preseizures.created_at) as min_created_at', 'MAX(pack_report_preseizures.created_at) as max_created_at', 'MAX(pack_report_preseizures.delivery_tried_at) as max_delivery_tried_at').first
  end
end
