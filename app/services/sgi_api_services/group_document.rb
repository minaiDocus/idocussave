# -*- encoding : UTF-8 -*-

class SgiApiServices::GroupDocument
  FILE_NAME_PATTERN_1 = /\A([A-Z0-9]+_*[A-Z0-9]*_[A-Z][A-Z0-9]+_\d{4}([01T]\d)*)_\d{3,4}\.pdf\z/i
  FILE_NAME_PATTERN_2 = /\A([A-Z0-9]+_*[A-Z0-9]*_[A-Z][A-Z0-9]+_\d{4}([01T]\d)*)_\d{3,4}_\d{3}\.pdf\z/i

  def initialize(json_content)
    @errors       = []
    @json_content = json_content
  end


  def execute
    if valid_json_content?
      @temp_pack = find_temp_pack(@json_content['pack_name'])

      @merged_dir = Dir.mktmpdir

      files_input

      create_new_temp_document

      @temp_pack.temp_documents.where(id: temp_document_ids(@json_content['pieces'])).each(&:bundled)

      clean_tmp

      { success: true }
    else
      @errors << { success: false }
      @errors.reduce { |accumulator_value, hash_value| (accumulator_value || {}).merge hash_value }
    end
  end

  def self.position(file_name)
    if FILE_NAME_PATTERN_1.match(file_name)
      file_name.split('_')[-1].to_i
    elsif FILE_NAME_PATTERN_2.match(file_name)
      file_name.split('_')[-2].to_i
    end
  end


  def self.basename(file_name)
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
      if temp_document.bundled?
        @errors << { "piece_already_bundled" => "Piece already bundled with an id : #{id} in pack name: #{@json_content['pack_name']}." }
      end
    else
      @errors << { "parent_temp_document_unknown" => "Unknown temp document with an id: #{id} in pack name: #{@json_content['pack_name']}." }
    end
  end


  def clean_tmp
    FileUtils.remove_entry @merged_dir if @merged_dir
  end

  def create_new_temp_document
    @json_content['pieces'].each do |pieces|
      pieces.each do |piece|
        merged_dir = File.join(@merged_dir, "#{piece['id']}")

        CreateTempDocumentFromGrouping.new(@temp_pack, piece['pages'], piece['id'], merged_dir).execute
      end
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

  def files_input
    temp_document_ids(@json_content['pieces']).uniq.each do |id|
      merged_dir = File.join(@merged_dir, "#{id}")
      FileUtils.mkdir_p merged_dir

      Pdftk.new.burst @temp_pack.temp_documents.where(id: id).first.cloud_content_object.path, merged_dir, 'page', DataProcessor::TempPack::POSITION_SIZE
    end
  end

  class CreateTempDocumentFromGrouping
    def initialize(temp_pack, pages, temp_document_id, merged_path)
      @temp_pack        = temp_pack
      @pages            = pages
      @temp_document_id = temp_document_id
      @file_name        = @temp_pack.name.tr(' ', '_') + '.pdf'
      @merged_path      = merged_path
    end

    # Create a secondary temp documents it comes back from grouping
    def execute
      Dir.mktmpdir do |tmpdir|
        @file_path = tmpdir

        @file_path = File.join(@file_path, @file_name)

        if file_paths.size > 1
          Pdftk.new.merge file_paths, @file_path
        else
          FileUtils.cp file_paths.first, @file_path
        end

        begin

          create_temp_document

        rescue => e
          log_document = {
            name: "SgiApiServices::CreateTempDocumentFromGrouping",
            error_group: "[sgi-api-services-create-temp-document-from-grouping] create temp document errors",
            erreur_type: "create temp document with errors",
            date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
            more_information: {
              temp_dir_path: @file_path,
              service_error: e.to_s
            }
          }

          ErrorScriptMailer.error_notification(log_document).deliver
        end
      end
    end

    private

    def file_paths
      @file_paths = @pages.map {|page| File.join(@merged_path, 'page_' + ("%03d" % page) + '.pdf') }
    end

    def temp_documents
      @temp_documents ||= @temp_pack.temp_documents.where(id: @temp_document_id).by_position
    end

    def original_temp_document
      temp_documents.first
    end

    def bundling_document_ids
      temp_documents.map(&:id) if original_temp_document.scanned?
    end

    def create_temp_document
      file_name                                 = File.basename(@file_path)

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
      temp_document.parent_document_id          = original_temp_document.id
      temp_document.scan_bundling_document_ids  = bundling_document_ids
      temp_document.analytic_reference_id       = original_temp_document.analytic_reference_id
      temp_document.original_fingerprint        = DocumentTools.checksum(@file_path)

      if temp_document.save && temp_document.ready
        temp_document.cloud_content_object.attach(File.open(@file_path), file_name)
        true
      else
        false
      end
    end
  end
end
