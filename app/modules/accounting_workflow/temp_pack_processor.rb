# -*- encoding : UTF-8 -*-
class AccountingWorkflow::TempPackProcessor
  POSITION_SIZE = 3

  def self.process(temp_pack)
    runner_id = SecureRandom.hex(4)
    temp_documents = temp_pack.ready_documents
    user_code = temp_pack.name.split[0]
    user = User.find_by_code user_code
    return false unless user && temp_documents.any?
    pack = Pack.find_or_initialize temp_pack.name, user
    current_piece_position = begin
                                 pack.pieces.by_position.last.position + 1
                               rescue
                                 1
                               end
    if pack.has_documents?
      current_page_position = begin
                                  pack.pages.by_position.last.position + 2
                                rescue
                                  1
                                end
    end

    published_temp_documents = []
    added_pieces = []
    invoice_pieces = []

    temp_documents.each_with_index do |temp_document, document_index|
      logger.info "[#{runner_id}] #{temp_pack.name.sub(' all', '')} (#{document_index+1}/#{temp_documents.size}) - n°#{temp_document.position} - #{temp_document.delivery_type} - #{temp_document.pages_number}p - start"
      if !temp_document.is_a_cover? || !pack.has_cover?
        Dir.mktmpdir do |dir|
          
          ## Initialization
          is_a_cover = temp_document.is_a_cover?
          basename = pack.name.sub(' all', '')
          piece_position = is_a_cover ? 0 : current_piece_position
          piece_name = DocumentTools.name_with_position(basename, piece_position, POSITION_SIZE)
          piece_file_name = DocumentTools.file_name(piece_name)
          piece_file_path = File.join(dir, piece_file_name)
          original_file_path = File.join(dir, 'original.pdf')

          FileUtils.cp temp_document.cloud_content_object.path, original_file_path

          DocumentTools.correct_pdf_if_needed original_file_path

          DocumentTools.create_stamped_file original_file_path, piece_file_path, user.stamp_name, piece_name, origin: temp_document.delivery_type,
                                                                                                              is_stamp_background_filled: user.is_stamp_background_filled,
                                                                                                              dir: dir,
                                                                                                              logger: logger

          pages_number = DocumentTools.pages_number piece_file_path

          ## Piece
          piece = Pack::Piece.new
          piece.organization          = user.organization
          piece.user                  = user
          piece.pack                  = pack
          piece.name                  = piece_name
          # piece.content               = open(piece_file_path)
          piece.origin                = temp_document.delivery_type
          piece.temp_document         = temp_document
          piece.is_a_cover            = is_a_cover
          piece.position              = piece_position
          piece.pages_number          = pages_number
          piece.analytic_reference_id = temp_document.analytic_reference_id
          piece.cloud_content_object.attach(File.open(piece_file_path), piece_file_name) if piece.save
          
          ##Temp fix issue imagemagick v 6 thumb generation (The piece will not have a thumb)
          ## REMOVE THIS after imagemagick upgrade
          # if !piece.valid? && !piece.persisted?
          #   DocumentTools.correct_pdf_if_needed piece_file_path
          #   piece.content = open(piece_file_path)
          #   piece.save

          #   if piece.valid? && piece.persisted?
          #     Pack::Piece.extract_content piece
          #     piece.update(is_finalized: true)
          #   end
          # end
          ##Temp fix issue imagemagick

          if temp_document.api_name == 'invoice_auto'
            invoice_pieces << piece
          else
            added_pieces << piece
          end

          # DocumentTools.sign_pdf(piece_file_path, piece.content.path)

          ## Dividers
          pack_divider              = pack.dividers.build
          pack_divider.type         = 'piece'
          pack_divider.origin       = temp_document.delivery_type
          pack_divider.is_a_cover   = is_a_cover
          pack_divider.name         = piece_file_name.sub('.pdf', '')
          pack_divider.pages_number = pages_number
          pack_divider.position     = piece_position
          pack_divider.save

          if temp_document.scanned?
            position = pack.dividers.sheets.not_covers.last.try(:position) || 0
            position = is_a_cover ? 0 : (position + 1)
            if temp_pack.is_bundle_needed?
              temp_document.scan_bundling_document_ids.each do |id|
                bundling_document         = TempDocument.find(id)
                base_file_name            = basename.tr(' ', '_')
                pack_divider              = pack.dividers.build
                pack_divider.pack         = pack
                pack_divider.type         = 'sheet'
                pack_divider.origin       = temp_document.delivery_type
                pack_divider.is_a_cover   = is_a_cover
                pack_divider.name         = base_file_name + "_%0#{POSITION_SIZE}d" % position
                pack_divider.pages_number = bundling_document.pages_number
                pack_divider.position     = position
                pack_divider.save
                position += 1
              end
            else
              base_file_name            = basename.tr(' ', '_')
              pack_divider              = pack.dividers.build
              pack_divider.pack         = pack
              pack_divider.type         = 'sheet'
              pack_divider.origin       = temp_document.delivery_type
              pack_divider.is_a_cover   = is_a_cover
              pack_divider.name         = base_file_name + "_%0#{POSITION_SIZE}d" % position
              pack_divider.pages_number = pages_number
              pack_divider.position     = position
              pack_divider.save
            end
          end

          ## Original document
          if pack.original_document.present?
            if pack.original_document.cloud_content_object.size.to_i < 400.megabytes
              if is_a_cover
                pack.prepend piece_file_path
              else
                pack.append piece_file_path
              end
            end
          end
          ## Pages
          if pack.has_documents?
            suffix = is_a_cover ? 'cover_page' : 'page'
            Pdftk.new.burst piece_file_path, dir, suffix, POSITION_SIZE

            Dir.glob("#{dir}/#{suffix}_*.pdf").sort.each_with_index do |file_path, index|
              position = is_a_cover ? (index + 1) : current_page_position
              page_name = DocumentTools.name_with_position(basename + " #{suffix}", position, POSITION_SIZE)
              page_file_name = DocumentTools.file_name(page_name)
              page_file_path = File.join(dir, page_file_name)
              page_file_signed_path = File.join(dir, page_file_name.gsub('.pdf', '_signed.pdf'))
              FileUtils.mv file_path, page_file_path

              page                = Document.new
              page.pack           = pack
              page.position       = is_a_cover ? (index - 2) : (current_page_position - 1)
              # page.content        = open(page_file_path)
              page.origin         = temp_document.delivery_type
              page.is_a_cover     = is_a_cover
              
              DocumentTools.sign_pdf(page_file_path, page_file_signed_path)
              page.cloud_content_object.attach(File.open(page_file_signed_path), page_file_name) if page.save

              current_page_position += 1 unless is_a_cover
            end
          end
          current_piece_position += 1 unless is_a_cover

          # piece.try(:sign_piece)
        end

        published_temp_documents << temp_document
      end
      temp_document.processed
      logger.info "[#{runner_id}] #{temp_pack.name.sub(' all', '')} (#{document_index+1}/#{temp_documents.size}) - n°#{temp_document.position} - #{temp_document.delivery_type} - #{temp_document.pages_number}p - end"
    end

    pack.set_original_document_id
    pack.set_content_url
    pack.set_pages_count
    pack.set_historic
    pack.set_tags
    pack.is_update_notified = false
    temp_pack.reload
    if temp_pack.document_bundling_count == 0 && temp_pack.document_bundle_needed_count == 0
      pack.is_fully_processed = true
    end
    pack.save
    Reporting.update(pack)

    #Do not archive piece's files any more because of active storage
    # piece_files_path = (added_pieces + invoice_pieces).map { |e| e.cloud_content_object.path }
    # piece_files_path.in_groups_of(50).each do |group|
    #   DocumentTools.archive(pack.archive_file_path, group)
    # end

    pieces_to_pre_assigned = []

    if temp_pack.is_pre_assignment_needed?
      if user.validate_ibiza_analyitcs?
        added_pieces.each do |piece|
          if piece.from_web? || piece.from_mobile?
            pieces_to_pre_assigned << piece
          else
            piece.waiting_analytics_pre_assignment
          end
        end
      else
        pieces_to_pre_assigned << added_pieces
      end

      pieces_to_pre_assigned.flatten!
      AccountingWorkflow::SendPieceToPreAssignment.execute(pieces_to_pre_assigned) if pieces_to_pre_assigned.any?

      AutoPreAssignedInvoicePieces.execute(invoice_pieces) if invoice_pieces.any?
    end

    FileDelivery.prepare(pack)

    published_temp_documents.each do |temp_document|
      NotifyPublishedDocument.new(temp_document).execute
    end
  end

  def self.logger
    @@logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_document_processor.log")
  end
end