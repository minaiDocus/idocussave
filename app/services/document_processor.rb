# -*- encoding : UTF-8 -*-
class DocumentProcessor
  POSITION_SIZE = 3

  class << self
    def process
      TempPack.not_processed.each do |temp_pack|
        temp_documents = temp_pack.ready_documents.entries
        user_code = temp_pack.name.split[0]
        user = User.find_by_code user_code
        if user && temp_documents.any?
          pack = Pack.find_or_initialize temp_pack.name, user
          current_piece_position = pack.pieces.by_position.last.position + 1 rescue 1
          current_page_position = pack.pages.by_position.last.position + 2 rescue 1
          temp_documents.each do |temp_document|
            if !temp_document.is_a_cover? || !pack.has_cover?
              Dir.mktmpdir do |dir|
                ## Initialization
                is_a_cover = temp_document.is_a_cover?
                basename = pack.name.sub(' all', '')
                piece_position = is_a_cover ? 0 : current_piece_position
                piece_name = DocumentTools.name_with_position(basename, piece_position, POSITION_SIZE)
                piece_file_name = DocumentTools.file_name(piece_name)
                piece_file_path = File.join(dir, piece_file_name)

                DocumentTools.create_stamped_file temp_document.content.path, piece_file_path, user.stamp_name, piece_name, {
                  origin: temp_document.delivery_type,
                  is_stamp_background_filled: user.is_stamp_background_filled,
                  dir: dir
                }

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
                  base_file_name = basename.gsub(' ', '_')
                  position = pack.dividers.sheets.not_covers.last.try(:position) || 0
                  position = is_a_cover ? 0 : (position + 1)
                  pack_divider              = pack.dividers.build
                  pack_divider.pack         = pack
                  pack_divider.type         = 'sheet'
                  pack_divider.origin       = temp_document.delivery_type
                  pack_divider.is_a_cover   = is_a_cover
                  pack_divider.name         = base_file_name + "_%0#{POSITION_SIZE}d" % position
                  pack_divider.pages_number = 2
                  pack_divider.position     = position
                  pack_divider.save
                end

                ## Original document
                if pack.original_document.present?
                  if is_a_cover
                    pack.original_document.prepend piece_file_path
                  else
                    pack.original_document.append piece_file_path
                  end
                else
                  new_file_name = pack.name.gsub(' ', '_') + '.pdf'
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
                  position = is_a_cover ? (index+1) : current_page_position
                  page_name = DocumentTools.name_with_position(basename + " #{suffix}", position, POSITION_SIZE)
                  page_file_name = DocumentTools.file_name(page_name)
                  page_file_path = File.join(dir, page_file_name)
                  FileUtils.mv file_path, page_file_path

                  page                = Document.new
                  page.pack           = pack
                  page.position       = is_a_cover ? (index-2) : (current_page_position-1)
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
          pack.save
          Reporting.update(pack)

          piece_files_path = pack.pieces.by_position.map { |e| e.content.path }
          DocumentTools.archive(pack.archive_file_path, piece_files_path)

          FileDeliveryInit.prepare(pack)
        end
      end
    end
  end
end
