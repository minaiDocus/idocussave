### Fiduceo related - remained untouched (or nearly) : to be deprecated soon ###
# -*- encoding : UTF-8 -*-
class FiduceoDocument
  attr_reader :temp_document

  def initialize(retriever, document)
    @retriever = retriever
    @user = retriever.user
    @journal = retriever.journal
    @document = document
    @fileb64 = document['binaryData']

    label = document['metadatas']['metadata'].select { |e| e['name'] == 'LIBELLE' }.first['value']
    @extension = document['metadatas']['metadata'].select { |e| e['name'] == 'FILE_EXTENSION' }.first['value']
    original_file_name = "#{label}#{@extension}"

    if valid?
      pack = TempPack.find_or_create_by_name pack_name
      options = {
        original_file_name:    original_file_name,
        delivered_by:          'fiduceo',
        delivery_type:         'fiduceo',
        signature:             document['documentHash'],
        user_id:               @user.id,
        fiduceo_metadata:      metadata,
        fiduceo_id:            document['id'],
        service_name:          retriever.service_name,
        custom_service_name:   retriever.name,
        is_content_file_valid: true,
        wait_selection:        wait_selection?
      }
      @temp_document = AddTempDocumentToTempPack.execute(pack, file, options)
      retriever.temp_documents << @temp_document
    end
    clean_tmp
  end

  def file_name
    "#{@user.code}_#{@journal.name}_#{period}.pdf"
  end

  def pack_name
    DocumentTools.pack_name file_name
  end

  private

  def valid?
    if @fileb64.empty?
      true
    else
      @valid ||= DocumentTools.modifiable?(file.path) && @extension.match(/\A\.pdf\z/i)
    end
  end

  def invalid?
    !valid?
  end

  def period_service
    @period_service ||= PeriodService.new user: @user
  end

  def period
    @period ||= Period.period_name period_service.period_duration, 0
  end

  def file
    if @fileb64.empty?
      nil
    else
      if @file
        @file
      else
        @dir = Dir.mktmpdir
        file_path = File.join(@dir, file_name)
        File.open file_path, 'w' do |f|
          f.write decoded_data
        end
        @file = File.open(file_path)
      end
    end
  end

  def clean_tmp
    FileUtils.remove_entry @dir if @dir
  end

  def decoded_data
    Base64.decode64(@fileb64.gsub(/\\n/, "\n"))
          .force_encoding('UTF-8')
  end

  def metadata
    @metadata ||= format_metadata(@document['metadatas']['metadata'])
  end

  def format_metadata(data)
    hsh = {}
    data.each do |e|
      hsh[e['name'].downcase] = e['value']
    end
    hsh['amount'] = hsh['amount'].to_f
    hsh['date'] = Time.zone.parse(hsh['date']).to_time
    hsh
  end

  def wait_selection?
    if @retriever.wait_selection?
      true
    elsif metadata['date'].present? && metadata['date'].is_a?(Time)
      metadata['date'] < 2.months.ago
    else
      false
    end
  end
end
