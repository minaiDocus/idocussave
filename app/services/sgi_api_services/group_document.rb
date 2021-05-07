# -*- encoding : UTF-8 -*-

class SgiApiServices::GroupDocument
  FILE_NAME_PATTERN_1 = /\A([A-Z0-9]+_*[A-Z0-9]*_[A-Z][A-Z0-9]+_\d{4}([01T]\d)*)_\d{3,4}\.pdf\z/i
  FILE_NAME_PATTERN_2 = /\A([A-Z0-9]+_*[A-Z0-9]*_[A-Z][A-Z0-9]+_\d{4}([01T]\d)*)_\d{3,4}_\d{3}\.pdf\z/i

  class << self
    def processing(json_content, _temp_document_ids, temp_pack_id)
      CustomUtils.mktmpdir('api_group_document') do |dir|
        temp_pack = TempPack.where(id: temp_pack_id).first

        if temp_pack
          create_new_temp_document(json_content, _temp_document_ids, dir, temp_pack)

          temp_pack.temp_documents.where(id: _temp_document_ids).each do |temp_document|
            if temp_document.children.size > 0
              temp_document.update(state: 'bundled')
            else
              mail_info = {
                subject: "[SgiApiServices::GroupDocument] create temp document errors (can't create a child)",
                name: "SgiApiServices::CreateTempDocumentFromGrouping-cannot-create-child",
                error_group: "[sgi-api-services-create-temp-document-from-grouping] create temp document errors (can't create a child)",
                erreur_type: "create temp document with errors - can't create a child",
                date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
                more_information: {
                  temp_document_id: temp_document.id,
                  temp_pack_id: temp_pack.id,
                  temp_pack_name: temp_pack.name
                }
              }

              ErrorScriptMailer.error_notification(mail_info).deliver
            end
          end
        end
      end
    end

    def position(file_name)
      if FILE_NAME_PATTERN_1.match(file_name)
        file_name.split('_')[-1].to_i
      elsif FILE_NAME_PATTERN_2.match(file_name)
        file_name.split('_')[-2].to_i
      end
    end


    def basename(file_name)
      if (result = FILE_NAME_PATTERN_1.match(file_name))
        if file_name.split('_').size == 5
          result[1].sub('_', '%').tr('_', ' ')
        else
          result[1].tr('_', ' ')
        end
      elsif (result = FILE_NAME_PATTERN_2.match(file_name))
        if file_name.split('_').size == 6
          result[1].sub('_', '%').tr('_', ' ')
        else
          result[1].tr('_', ' ')
        end
      end
    end

    def create_new_temp_document(json_content, _temp_document_ids, merged_dir, temp_pack)
      json_content['pieces'].each do |pieces|
        try_again = 0

        begin
          files_input(_temp_document_ids, merged_dir, temp_pack)

          pages       = []
          ids         = pieces.map{|piece| piece['id'] }
          merged_dirs = pieces.map{|piece| File.join(merged_dir, "#{piece['id']}")}
          pieces.map{|piece| pages << piece['pages']}

          result = CreateTempDocumentFromGrouping.new(temp_pack, pages, ids, merged_dirs, try_again).execute

          raise if !result && try_again < 3
        rescue
          FileUtils.rm_rf(Dir["#{merged_dir}/*"])

          sleep(10)

          try_again += 1
          retry
        end
      end
    end

    def files_input(_temp_document_ids, _merged_dir, temp_pack)
      _temp_document_ids.each do |id|
        merged_dir = File.join(_merged_dir, "#{id}")
        FileUtils.mkdir_p merged_dir

        Pdftk.new.burst temp_pack.temp_documents.where(id: id).first.cloud_content_object.path, merged_dir, "page_#{id}", DataProcessor::TempPack::POSITION_SIZE
      end
    end
  end

  def initialize(json_content)
    @errors       = []
    @json_content = json_content
  end


  def execute
    if valid_json_content?
      json_content       = @json_content
      temp_pack          = find_temp_pack(json_content['pack_name'])
      _temp_document_ids = temp_document_ids(json_content['pieces']).uniq

      staffing = StaffingFlow.new({ kind: 'grouping', params: { json_content: json_content, temp_document_ids: _temp_document_ids, temp_pack_id: temp_pack.id } }).save

      { success: true }
    else
      @errors << { success: false }
      @errors.reduce { |accumulator_value, hash_value| (accumulator_value || {}).merge hash_value }
    end
  end

  private

  def find_temp_pack(name)
    TempPack.where(name: CustomUtils.replace_code_of(name).tr('_', ' ') + ' all').first
  end


  def valid_json_content?
    if (temp_pack = find_temp_pack(@json_content['pack_name']))
      temp_document_ids(@json_content['pieces']).uniq.each do |id|
        verify_temp_document_bundled temp_pack, id
      end
    else
      @errors << { "pack_name_unknown" => "Pack name : #{@json_content['pack_name']}, unknown." }
    end

    @errors.empty?
  end


  def verify_temp_document_bundled(temp_pack, id)
    basename = @json_content['pack_name'].split(' ')[0]
    basename = CustomUtils.replace_code_of(basename)

    is_basename_match = temp_pack.name.match(/\A#{basename}/)
    temp_document     = temp_pack.temp_documents.where(id: id).first

    if is_basename_match && temp_document
      if temp_document.children.size > 0 || temp_document.bundled?
        temp_document.update(state: 'bundled')
        @errors << { "piece_already_bundled" => "Piece already bundled with an id : #{id} in pack name: #{@json_content['pack_name']}." }
      end
    else
      @errors << { "parent_temp_document_unknown" => "Unknown temp document with an id: #{id} in pack name: #{@json_content['pack_name']}." }
    end
  end


  def temp_document_ids(bundled_temp_documents)
    bundled_temp_documents.inject([]) do |result, element|
      result + if element.is_a?(Array)
        temp_document_ids(element)
      else
        [element['id']]
      end
    end
  end

  class CreateTempDocumentFromGrouping
    def initialize(temp_pack, pages, temp_document_ids, merged_paths, try_again)
      @temp_pack         = temp_pack
      @pages             = pages
      @temp_document_ids = temp_document_ids
      @file_name         = @temp_pack.name.gsub(' all', '').tr(' ', '_') + '.pdf'
      @merged_paths      = merged_paths
      @try_again         = try_again
    end

    # Create a secondary temp documents it comes back from grouping
    def execute
      CustomUtils.mktmpdir('api_group_document_2', nil, false) do |dir|
        @file_path = dir

        @file_path = File.join(@file_path, @file_name)

        if file_paths.size > 1
          is_ok = Pdftk.new.merge file_paths, @file_path
        else
          is_ok = true
          FileUtils.cp file_paths.first, @file_path
        end

        begin

          if is_ok
            return create_temp_document
          else
            return false if @try_again < 3

            log_document = {
              subject: "[SgiApiServices::GroupDocument] create temp document errors - can't be merge and retry in 10 minutes later",
              name: "SgiApiServices::CreateTempDocumentFromGrouping",
              error_group: "[sgi-api-services-create-temp-document-from-grouping] create temp document errors - can't be merge and retry in 10 minutes later",
              erreur_type: "create temp document with errors - can't be merge",
              date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
              more_information: {
                temp_pack_name: @temp_pack.name,
                parent_document_ids: @temp_document_ids.join(' && '),
                pages_should_be_merged: @pages.join(' && '),
                retries_counter: @try_again,
                destinations_path: @file_path,
                source_array: file_paths.join(' && ')
              }
            }

            begin
              ErrorScriptMailer.error_notification(log_document, { attachements: store_failed_merge_attachment } ).deliver
            rescue
              ErrorScriptMailer.error_notification(log_document).deliver
            end

            create_temp_document(true)

            return true
          end
        rescue => e
          return false if @try_again < 3

          log_document = {
            subject: "[SgiApiServices::GroupDocument] create temp document errors (can't be merge)",
            name: "SgiApiServices::CreateTempDocumentFromGrouping-error",
            error_group: "[sgi-api-services-create-temp-document-from-grouping] create temp document errors (can't be merge)",
            erreur_type: "create temp document with errors",
            date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
            more_information: {
              retries_counter: @try_again,
              temp_dir_path: @file_path,
              service_error: e.to_s
            }
          }

          ErrorScriptMailer.error_notification(log_document).deliver

          return true
        end
      end
    end

    private

    def store_failed_merge_attachment
      files = []

      file_paths.each do |file_path|
        files <<  {name: File.basename(file_path), file: File.read(file_path)}
      end

      files
    end

    def parents_documents_pages
      @parents_documents_pages = []
      @temp_document_ids.each_with_index {|temp_document_id, page| @parents_documents_pages << { parent_document_id: temp_document_id, pages: @pages[page] }}
      @parents_documents_pages
    end

    def file_paths
      _file_paths = []

      @pages.each_with_index do |pages, index_page|
        pages.map{|page| _file_paths << File.join(@merged_paths[index_page], "page_#{@temp_document_ids[index_page]}_" + ("%03d" % page) + ".pdf") }
      end

      _file_paths
    end

    def temp_documents
      @temp_documents ||= @temp_pack.temp_documents.where(id: @temp_document_ids).by_position
    end

    def original_temp_document
      temp_documents.first
    end

    def bundling_document_ids
      temp_documents.map(&:id) if original_temp_document.scanned?
    end

    def create_temp_document(recreate_later = false)
      file_name     = File.basename(@file_path)
      parents_pages = parents_documents_pages
      checksum      = DocumentTools.checksum(@file_path)

      found_with_parents  = TempDocument.where(parents_documents_pages: parents_pages).first
      found_with_checksum = TempDocument.where(original_fingerprint: checksum).where.not(parents_documents_ids: []).first

      return true if found_with_parents || found_with_checksum

      temp_document                             = TempDocument.new
      temp_document.temp_pack                   = @temp_pack
      temp_document.user                        = @temp_pack.user
      temp_document.organization                = @temp_pack.organization
      temp_document.position                    = @temp_pack.next_document_position
      temp_document.content_file_name           = file_name.gsub('.pdf', '')
      temp_document.pages_number                = DocumentTools.pages_number @file_path
      temp_document.is_an_original              = false
      temp_document.is_a_cover                  = original_temp_document.is_a_cover?
      temp_document.delivered_by                = original_temp_document.delivered_by
      temp_document.delivery_type               = original_temp_document.delivery_type
      temp_document.api_name                    = original_temp_document.api_name
      temp_document.parents_documents_ids       = @temp_document_ids
      temp_document.parents_documents_pages     = parents_pages
      temp_document.scan_bundling_document_ids  = bundling_document_ids
      temp_document.analytic_reference_id       = original_temp_document.analytic_reference_id
      temp_document.original_fingerprint        = checksum

      if temp_document.save
        temp_document.ready

        if(recreate_later)
          TempDocument.delay_for(10.minutes, queue: :low).recreate_grouped_document(temp_document.id)
        else
          temp_document.cloud_content_object.attach(File.open(@file_path), file_name) if File.exist?(@file_path)
        end
        true
      else
        mail_info = {
          subject: "[SgiApiServices::GroupDocument] can't create a new temp document from grouping",
          name: "SgiApiServices::CreateTempDocumentFromGrouping-cannot-create-child",
          error_group: "[sgi-api-services-create-temp-document-from-grouping] can't create a new temp document from grouping",
          erreur_type: "create temp document with errors - can't create a new temp document from grouping",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            errors_messages: errors.messages.to_s,
            parents_documents_infos: parents_pages.to_s,
            temp_pack_name: @temp_pack.name
          }
        }

        ErrorScriptMailer.error_notification(mail_info).deliver

        false
      end
    end
  end
end
