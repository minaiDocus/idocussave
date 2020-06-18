# -*- encoding : UTF-8 -*-
require 'open-uri'

class SgiApiServices::CreateTempDocumentFromGrouping
  def initialize(piece_url, temp_pack, file_name)
    @piece_url = piece_url
    @temp_pack = temp_pack
    @file_name = file_name
  end

  # Create a secondary temp documents it comes back from grouping
  def execute
    Dir.mktmpdir do |tmpdir|
      @file_path = File.join tmpdir

      download = open(@piece_url)

      IO.copy_stream(download, "#{@file_path}/#{@file_name}")

      @file_path = File.join(@file_path, @file_name)

      begin

        create_temp_document

        temp_documents.each(&:bundled)
      rescue => e
        log_document = {
          name: "SgiApiServices::CreateTempDocumentFromGrouping",
          error_group: "[sgi-api-services-create-temp-document-from-grouping] piece url is unreadable",
          erreur_type: "Piece url is unreadable",
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

  def temp_document_positions
    @piece_positions ||= SgiApiServices::GroupDocument.position(@file_name)
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
