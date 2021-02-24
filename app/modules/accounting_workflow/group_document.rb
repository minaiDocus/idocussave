# -*- encoding : UTF-8 -*-
class AccountingWorkflow::GroupDocument
  FILE_NAME_PATTERN_1 = /\A([A-Z0-9]+_*[A-Z0-9]*_[A-Z][A-Z0-9]+_\d{4}([01T]\d)*)_\d{3,4}\.pdf\z/i
  FILE_NAME_PATTERN_2 = /\A([A-Z0-9]+_*[A-Z0-9]*_[A-Z][A-Z0-9]+_\d{4}([01T]\d)*)_\d{3,4}_\d{3}\.pdf\z/i

  @@schema = Nokogiri::XML::Schema(Rails.root.join('lib/xsd/group_documents.xsd'))

  def self.process(file_path)
    UniqueJobs.for "GroupDocument-#{file_path}", 1.day, 2 do
      AccountingWorkflow::GroupDocument.new(file_path).execute if File.exist?(file_path)
    end
  end

  def initialize(file_path)
    @errors               = []
    @processed_file_paths = []
    @xml_file_path        = file_path
  end


  def execute
    if valid_result_data?
      document.css('pack').each do |pack_tag|
        temp_pack = find_temp_pack(pack_tag['name'])

        pack_tag.css('piece').each do |piece_tag|
          file_names = piece_tag.css('file_name').map(&:content)

          grouper = AccountingWorkflow::CreateTempDocumentFromGrouping.new(temp_pack, file_names, piece_tag['origin'])
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

  class << self
    def execute
      processable_results.map do |file_path|
        new(file_path).execute
      end
    end

    def processable_results
      Dir.glob(AccountingWorkflow.grouping_dir.join('output/*.xml')).select do |file_path|
        File.atime(file_path) < 1.minute.ago
      end
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

  def document
    @document ||= Nokogiri::XML(File.read(@xml_file_path))
  end


  def find_temp_pack(name)
    TempPack.where(name: CustomUtils.replace_code_of(name).tr('_', ' ') + ' all').first
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

      basename = CustomUtils.replace_code_of(basename)

      is_basename_match = temp_pack.name.match(/\A#{basename}/)

      temp_document = temp_pack.temp_documents.where(position: position).first

      if is_basename_match && temp_document
        if temp_document.bundled?
          @errors << "File name : \"#{file_name}\", already grouped."
        elsif !File.exist?(AccountingWorkflow.grouping_dir.join(origin + 's', file_name))
          @errors << "File name : \"#{file_name}\", not found."
        end
      else
        @errors << "File name : \"#{file_name}\", unknown."
      end
    end
  end


  def write_errors_to_file
    FileUtils.mkdir_p AccountingWorkflow.grouping_dir.join('errors')
    FileUtils.mv @xml_file_path, AccountingWorkflow.grouping_dir.join('errors')
    File.write AccountingWorkflow.grouping_dir.join("errors/#{File.basename(@xml_file_path, '.xml')}.txt"), @errors.join("\n")
  end


  def archive_path
    @archive_path ||= AccountingWorkflow.grouping_dir.join('archives', Date.today.strftime('%Y/%m/%d'))
  end


  def archive
    begin
      FileUtils.mkdir_p archive_path
      FileUtils.mv @xml_file_path, archive_path
      @processed_file_paths.each do |file_path|
        FileUtils.mv file_path, archive_path
      end
    rescue => e
      log_detail = {
        subject: "[AccountingWorkflow::GroupDocument] group document archive rescue #{e.message}",
        name: "AccountingWorkflow::GroupDocument",
        error_group: "[accounting_workflow-group_document] group document archive rescue",
        erreur_type: "Group document archive rescue",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          method: "archive",
          error: e.to_s
        }
      }

      ErrorScriptMailer.error_notification(log_detail).deliver
    end
  end
end
