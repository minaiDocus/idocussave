# -*- encoding : UTF-8 -*-
class PrepaCompta::GroupDocument
  RESULT_FILE_PATH = PrepaCompta.grouping_dir.join('result.xml')
  FILE_NAME_PATTERN_1 = /\A([A-Z0-9]+_*[A-Z0-9]*_[A-Z][A-Z0-9]+_\d{4}([01T]\d)*)_\d{3,4}\.pdf\z/i
  FILE_NAME_PATTERN_2 = /\A([A-Z0-9]+_*[A-Z0-9]*_[A-Z][A-Z0-9]+_\d{4}([01T]\d)*)_\d{3,4}_\d{3}\.pdf\z/i

  @@schema = Nokogiri::XML::Schema(Rails.root.join('lib/xsd/group_documents.xsd'))

  class << self
    def execute
      new.execute
    end

    def position(file_name)
      if FILE_NAME_PATTERN_1.match(file_name)
        file_name.split('_')[-1].to_i
      elsif FILE_NAME_PATTERN_2.match(file_name)
        file_name.split('_')[-2].to_i
      else
        nil
      end
    end

    def basename(file_name)
      if (result=FILE_NAME_PATTERN_1.match(file_name))
        if file_name.split('_').size == 5
          result[1].sub('_', '%').gsub('_', ' ')
        else
          result[1].gsub('_', ' ')
        end
      elsif (result=FILE_NAME_PATTERN_2.match(file_name))
        if file_name.split('_').size == 6
          result[1].sub('_', '%').gsub('_', ' ')
        else
          result[1].gsub('_', ' ')
        end
      else
        nil
      end
    end
  end

  def initialize
    @errors               = []
    @processed_file_paths = []
  end

  def execute
    if processable_result?
      if valid_result_data?
        document.css('pack').each do |pack_tag|
          temp_pack = find_temp_pack(pack_tag['name'])
          pack_tag.css('piece').each do |piece_tag|
            file_names = piece_tag.css('file_name').map(&:content)
            grouper = PrepaCompta::GroupIntoPiece.new(temp_pack, file_names, piece_tag['origin'])
            grouper.execute
            @processed_file_paths += grouper.file_paths
          end
        end
        archive
        true
      else
        write_errors_to_file
        false
      end
    end
  end

private

  def processable_result?
    File.exist?(RESULT_FILE_PATH) && File.mtime(RESULT_FILE_PATH) <= 1.minute.ago
  end

  def document
    @document ||= Nokogiri::XML(File.read(RESULT_FILE_PATH))
  end

  def find_temp_pack(name)
    TempPack.where(name: name.gsub('_', ' ') + ' all').first
  end

  def valid_result_data?
    schema_errors = @@schema.validate(document).map(&:to_s)
    if schema_errors.empty?
      verify_data
    else
      @errors += schema_errors
      false
    end
  end

  def verify_data
    document.css('pack').each do |pack_tag|
      if (temp_pack = find_temp_pack(pack_tag['name']))
        file_names = document.css('file_name').map(&:content)
        if file_names.uniq.size != file_names.size
          @errors << "File name : #{file_names.size - file_names.uniq.size} duplicate(s)."
        else
          pack_tag.css('piece').each do |piece_tag|
            file_names = piece_tag.css('file_name').map(&:content)
            verify_piece temp_pack, file_names, piece_tag['origin']
          end
        end
      else
        @errors << "Pack name : \"#{pack_tag['name']}\", unknown."
      end
    end
    @errors.empty?
  end

  def verify_piece(temp_pack, file_names, origin)
    if origin.in?(%w(scan dematbox_scan upload))
      file_names.uniq.each do |file_name|
        verify_file_name temp_pack, file_name, origin
      end
    else
      @errors << "Piece origin : \"#{origin}\", unknown."
    end
  end

  def verify_file_name(temp_pack, file_name, origin)
    file_name_parts = file_name.split('_')

    if (origin == 'scan' && !FILE_NAME_PATTERN_1.match(file_name)) || (origin != 'scan' && !FILE_NAME_PATTERN_2.match(file_name))
      @errors << "File name : \"#{file_name}\", does not match origin : \"#{origin}\"."
    else
      position = self.class.position(file_name)
      basename = self.class.basename(file_name)
      is_basename_match = temp_pack.name.match(/\A#{basename}/)
      temp_document = temp_pack.temp_documents.where(position: position).first
      if is_basename_match && temp_document
        if temp_document.bundled?
          @errors << "File name : \"#{file_name}\", already grouped."
        elsif !File.exist?(PrepaCompta.grouping_dir.join(origin + 's', file_name))
          @errors << "File name : \"#{file_name}\", not found."
        end
      else
        @errors << "File name : \"#{file_name}\", unknown."
      end
    end
  end

  def write_errors_to_file
    POSIX::Spawn::system "rm #{PrepaCompta.grouping_dir.join('result.xml')}"
    File.write PrepaCompta.grouping_dir.join('errors.txt'), @errors.join("\n")
  end

  def base_archive_path
    @base_archive_path ||= PrepaCompta.grouping_dir.join('archives', Date.today.strftime('%Y/%m/%d'))
  end

  def archive_path
    @archive_path ||= base_archive_path.to_s + "_#{process_number}"
  end

  def process_number
    if File.exist?(base_archive_path)
      Dir.glob(base_archive_path.join('*')).size + 1
    else
      1
    end
  end

  def archive
    POSIX::Spawn::system "mkdir -p #{archive_path}"
    POSIX::Spawn::system "mv #{RESULT_FILE_PATH} #{archive_path}"
    @processed_file_paths.each do |file_path|
      POSIX::Spawn::system "mv #{file_path} #{archive_path}"
    end
  end
end
