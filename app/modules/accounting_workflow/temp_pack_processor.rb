# -*- encoding : UTF-8 -*-
class AccountingWorkflow::TempPackProcessor
  POSITION_SIZE = 3

  def self.process(temp_pack)
    temp_documents = temp_pack.ready_documents
    user_code = temp_pack.name.split[0]
    user = User.find_by_code user_code
    exit unless user && temp_documents.any?
    logger.info "#{temp_pack.name} - #{temp_documents.size}"
    pack = Pack.find_or_initialize temp_pack.name, user
    current_piece_position = begin
                                 pack.pieces.by_position.last.position + 1
                               rescue
                                 1
                               end
    current_page_position = begin
                                pack.pages.by_position.last.position + 2
                              rescue
                                1
                              end
    added_pieces = []
    temp_documents.each do |temp_document|
      logger.info "   #{temp_document.position} - #{temp_document.delivery_type} - #{temp_document.pages_number}"
      if !temp_document.is_a_cover? || !pack.has_cover?
        Dir.mktmpdir do |dir|
          ## Initialization
          is_a_cover = temp_document.is_a_cover?
          basename = pack.name.sub(' all', '')
          piece_position = is_a_cover ? 0 : current_piece_position
          piece_name = DocumentTools.name_with_position(basename, piece_position, POSITION_SIZE)
          piece_file_name = DocumentTools.file_name(piece_name)
          piece_file_path = File.join(dir, piece_file_name)

          if temp_document.mongo_id
            temp_document_path = "#{Rails.root}/files/#{Rails.env}/#{temp_document.class.table_name}/#{temp_document.mongo_id}/#{temp_document.content_file_name}"
          else
            temp_document_path = "#{Rails.root}/files/#{Rails.env}/#{temp_document.class.table_name}/#{temp_document.id}/#{temp_document.content_file_name}"
          end
          DocumentTools.create_stamped_file temp_document_path, piece_file_path, user.stamp_name, piece_name, origin: temp_document.delivery_type,
                                                                                                                      is_stamp_background_filled: user.is_stamp_background_filled,
                                                                                                                      dir: dir

          pages_number = DocumentTools.pages_number piece_file_path

          ## Piece
          piece = Pack::Piece.new
          piece.organization  = user.organization
          piece.user          = user
          piece.pack          = pack
          piece.name          = piece_name
          piece.content       = open(piece_file_path)
          piece.origin        = temp_document.delivery_type
          piece.temp_document = temp_document
          piece.is_a_cover    = is_a_cover
          piece.position      = piece_position
          piece.save
          added_pieces << piece

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
          end

          ## Original document
          if pack.original_document.present?
            if pack.original_document.content_file_size < 400.megabytes
              if is_a_cover
                pack.original_document.prepend piece_file_path
              else
                pack.original_document.append piece_file_path
              end
            end
          else
            new_file_name = pack.name.tr(' ', '_') + '.pdf'
            new_file_path = File.join(dir, new_file_name)
            FileUtils.copy piece_file_path, new_file_path

            document                = Document.new
            document.pack           = pack
            document.content        = open(new_file_path)
            document.origin         = 'mixed'
            document.is_a_cover     = false
            document.position       = nil

            document.save
          end
          ## Pages
          suffix = is_a_cover ? 'cover_page' : 'page'
          Pdftk.new.burst piece_file_path, dir, suffix, POSITION_SIZE

          Dir.glob("#{dir}/#{suffix}_*.pdf").sort.each_with_index do |file_path, index|
            position = is_a_cover ? (index + 1) : current_page_position
            page_name = DocumentTools.name_with_position(basename + " #{suffix}", position, POSITION_SIZE)
            page_file_name = DocumentTools.file_name(page_name)
            page_file_path = File.join(dir, page_file_name)
            FileUtils.mv file_path, page_file_path

            page                = Document.new
            page.pack           = pack
            page.position       = is_a_cover ? (index - 2) : (current_page_position - 1)
            page.content        = open(page_file_path)
            page.origin         = temp_document.delivery_type
            page.is_a_cover     = is_a_cover
            page.save

            current_page_position += 1 unless is_a_cover
          end
          current_piece_position += 1 unless is_a_cover
        end
      end
      temp_document.processed
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

    piece_files_path = added_pieces.map { |e| e.content.path }
    piece_files_path.in_groups_of(50).each do |group|
      DocumentTools.archive(pack.archive_file_path, group)
    end

    if temp_pack.is_pre_assignment_needed?
      AccountingWorkflow::SendPieceToPreAssignment.execute(added_pieces)
    end
    FileDelivery.prepare(pack)
  end

  def self.logger
    @@logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_document_processor.log")
  end
end
