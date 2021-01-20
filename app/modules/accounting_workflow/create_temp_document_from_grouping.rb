# -*- encoding : UTF-8 -*-
class AccountingWorkflow::CreateTempDocumentFromGrouping
  def initialize(temp_pack, file_names, origin)
    @temp_pack  = temp_pack
    @file_names = file_names
    @origin     = origin
  end


  # Create a secondary temp documents it comes back from grouping
  def execute
    Dir.mktmpdir(nil, Rails.root.join('tmp/')) do |tmpdir|
      file_path = File.join tmpdir, @temp_pack.basefilename

      if file_paths.size > 1
        Pdftk.new.merge file_paths, file_path
      else
        FileUtils.cp file_paths.first, file_path
      end

      create_temp_document(file_path)

      temp_documents.each(&:bundled)
    end
  end


  def file_paths
    @file_paths ||= @file_names.map do |file_name|
      AccountingWorkflow.grouping_dir.join((@origin + 's'), file_name)
    end
  end


  def temp_document_positions
    @piece_positions ||= @file_names.map do |file_name|
      AccountingWorkflow::GroupDocument.position(file_name)
    end
  end


  def temp_documents
    @temp_documents ||= @temp_pack.temp_documents.where(position: temp_document_positions).by_position
  end


  def original_temp_document
    temp_documents.first
  end


  def bundling_document_ids
    temp_documents.map(&:id) if original_temp_document.scanned?
  end


  private


  def create_temp_document(file_path)
    file_name                                 = File.basename(file_path)
    temp_document                             = TempDocument.new
    temp_document.temp_pack                   = @temp_pack
    temp_document.user                        = @temp_pack.user
    temp_document.organization                = @temp_pack.organization
    temp_document.position                    = @temp_pack.next_document_position
    # temp_document.content                     = open file_path
    temp_document.content_file_name           = File.basename(file_path).gsub('.pdf', '')
    temp_document.pages_number                = DocumentTools.pages_number file_path
    temp_document.is_an_original              = false
    temp_document.is_a_cover                  = original_temp_document.is_a_cover?
    temp_document.delivered_by                = original_temp_document.delivered_by
    temp_document.delivery_type               = original_temp_document.delivery_type
    temp_document.api_name                    = original_temp_document.api_name
    temp_document.parent_document_id          = original_temp_document.id
    temp_document.scan_bundling_document_ids  = bundling_document_ids
    temp_document.analytic_reference_id       = original_temp_document.analytic_reference_id
    temp_document.original_fingerprint        = DocumentTools.checksum(file_path)

    if temp_document.save && temp_document.ready
      temp_document.cloud_content_object.attach(File.open(file_path), file_name)
      true
    else
      false
    end
  end
end
