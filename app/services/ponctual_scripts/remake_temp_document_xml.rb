class PonctualScripts::RemakeTempDocumentXml < PonctualScripts::PonctualScript
  def self.execute(file_names=[])
    new({file_names: file_names}).run
  end

  private

  def execute
    @schema = Nokogiri::XML::Schema(Rails.root.join('lib/xsd/group_documents.xsd'))
    @errors = []
    basepath = '/nfs/staffing/grouping/errors/'

    @options[:file_names].each do |xml_file_name|
      @xml_file_path = basepath + xml_file_name
      @_document     = Nokogiri::XML(File.read(@xml_file_path))

      if valid_result_data?
        document.css('pack').each do |pack_tag|
          temp_pack = find_temp_pack(pack_tag['name'])
          user = temp_pack.user

          file_name = pack_tag.css('piece').first.css('file_name')

          position  = AccountingWorkflow::GroupDocument.position(file_name.first.content)

          parent_document = user.temp_documents.where(state: 'bundled', position: position).first

          next if parent_document.nil?

          temp_documents = user.temp_documents.where(parent_document_id: parent_document.id)

          piece_counter = 0
          real_counter = 0

          pack_tag.css('piece').each do |piece_tag|
            real_counter += 1

            next if piece_tag['number'].to_i <= temp_documents.size

            file_names = piece_tag.css('file_name').map(&:content)

            grouper = AccountingWorkflow::CreateTempDocumentFromGrouping.new(temp_pack, file_names, piece_tag['origin'])
            grouper.execute

            piece_counter += 1
          end

          logger_infos "[RemakeTempDocumentXml] - Filename: #{xml_file_name} - ParentDoc: #{parent_document.id} - RealCount: #{real_counter} - Injected: #{piece_counter}"
        end
      else
        logger_infos "[RemakeTempDocumentXml] - Filename: #{xml_file_name} - Error: #{@errors.join(' ')}"
        write_errors_to_file
      end
    end
  end

  def document
    @_document
  end

  def find_temp_pack(name)
    TempPack.where(name: CustomUtils.replace_code_of(name).tr('_', ' ') + ' all').first
  end

  def valid_result_data?
    schema_errors = @schema.validate(document).map(&:to_s)
    if schema_errors.empty?
      verify_data
    else
      @errors += schema_errors
      false
    end
  end

  def verify_data
    document.css('pack').each do |pack_tag|
      if find_temp_pack(pack_tag['name'])
        file_names = document.css('file_name').map(&:content)
        if file_names.uniq.size != file_names.size
          @errors << "File name : #{file_names.size - file_names.uniq.size} duplicate(s)."
        end
      else
        @errors << "Pack name : \"#{pack_tag['name']}\", unknown."
      end
    end

    @errors.empty?
  end

  def write_errors_to_file
    FileUtils.mkdir_p AccountingWorkflow.grouping_dir.join('errors')
    FileUtils.mv @xml_file_path, AccountingWorkflow.grouping_dir.join('errors')
    File.write AccountingWorkflow.grouping_dir.join("errors/#{File.basename(@xml_file_path, '.xml')}_ponctual.txt"), @errors.join("\n")
  end
end