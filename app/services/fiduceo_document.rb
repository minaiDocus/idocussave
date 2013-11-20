# -*- encoding : UTF-8 -*-
class FiduceoDocument
  attr_reader :temp_document

  def initialize(transaction, document)
    @user = transaction.user
    @journal = transaction.retriever.journal
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
        fiduceo_id:            document['id'],
        is_content_file_valid: true,
        is_locked:             transaction.retriever.wait_user_action?
      }
      @temp_document = pack.add file, options
      transaction.temp_documents << @temp_document
      transaction.retriever.temp_documents << @temp_document
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

  def period_duration
    @user.periods.last.duration rescue 1
  end

  def period
    @period ||= Scan::Period.period_name period_duration, true
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
        @file = File.open(file_path, 'w')
        @file.write decoded_data
        @file.close
        @file
      end
    end
  end

  def clean_tmp
    FileUtils.remove_entry @dir if @dir
  end

  def decoded_data
    Base64::decode64(@fileb64.gsub(/\\n/,"\n")).
      force_encoding('UTF-8')
  end
end
