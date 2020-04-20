# -*- encoding : UTF-8 -*-
class AccountingWorkflow::TempPackProcessor
  POSITION_SIZE = 3

  def self.process(temp_pack_name)
    UniqueJobs.for "PublishDocument-#{temp_pack_name}", 2.hours, 2 do
      temp_pack = TempPack.find_by_name temp_pack_name
      execute(temp_pack) if temp_pack.not_processed?
      sleep(60) #lock multi temp pack processing to avoid access disk overload
    end
  end

  def self.execute(temp_pack)
    runner_id = SecureRandom.hex(4)
    temp_documents = temp_pack.ready_documents
    user_code = temp_pack.name.split[0]
    user = User.find_by_code user_code

    return false unless user && temp_documents.any?

    pack = Pack.find_or_initialize temp_pack.name, user
    current_piece_position = begin
                                 pack.pieces.unscoped.where(pack_id: pack.id).by_position.last.position + 1
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
    added_pieces             = []
    invoice_pieces           = []
    recreate_original        = false

    sleep_counter = 5
    dir = "#{Rails.root}/files/#{Rails.env}/temp_pack_processor/#{temp_pack.name.downcase.tr(' %','__')}/"

    FileUtils.makedirs(dir)
    FileUtils.chmod(0755, dir)

    next_original_document = pack.original_document.cloud_content_object.path.to_s
    next_original_document = File.join(dir, "next_original_#{Time.now.strftime('%Y%m%d%H%M%S')}.pdf") if !File.exist?(next_original_document)
    is_locked              = pack.is_locked?
    pack.update(locked_at: Time.now)

      temp_documents.each_with_index do |temp_document, document_index|
        #add a sleeping time to prevent disk access overload
        sleep_counter -= 1
        if sleep_counter <= 0
          sleep(7)
          sleep_counter = 5
        end

        LogService.info('document_processor', "[#{runner_id}] #{temp_pack.name.sub(' all', '')} (#{document_index+1}/#{temp_documents.size}) - n°#{temp_document.position} - #{temp_document.delivery_type} - #{temp_document.pages_number}p - start")
        inserted_piece = nil
        if !temp_document.is_a_cover? || !pack.has_cover?
          inserted_piece = temp_document.piece

          if !inserted_piece
            ## Initialization
            is_a_cover = temp_document.is_a_cover?
            basename = pack.name.sub(' all', '')
            piece_position = is_a_cover ? 0 : current_piece_position
            piece_name = DocumentTools.name_with_position(basename, piece_position, POSITION_SIZE)
            piece_file_name = DocumentTools.file_name(piece_name)
            piece_file_path = File.join(dir, piece_file_name)
            original_file_path = File.join(dir, 'original.pdf')

            begin
              FileUtils.cp temp_document.cloud_content_object.path, original_file_path
            rescue
              next
            end

            DocumentTools.correct_pdf_if_needed original_file_path

            DocumentTools.create_stamped_file original_file_path, piece_file_path, user.stamp_name, piece_name, origin: temp_document.delivery_type,
                                                                                                                is_stamp_background_filled: user.is_stamp_background_filled,
                                                                                                                dir: dir

            pages_number = DocumentTools.pages_number piece_file_path

            ## Piece
            piece                       = Pack::Piece.new
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
            inserted_piece              = piece

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
            if !is_locked && pack.original_document.present?
              if pack.original_document.cloud_content_object.size.to_i < 400.megabytes
                if is_a_cover
                  pack.prepend piece_file_path, dir, next_original_document
                else
                  recreate_original = true if !pack.append(piece_file_path, dir, next_original_document)
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

            piece.try(:sign_piece)

            published_temp_documents << temp_document
          else
            LogService.info('document_processor', "[#{runner_id}] #{temp_pack.name.sub(' all', '')} (#{document_index+1}/#{temp_documents.size}) - n°#{temp_document.position} - #{inserted_piece.try(:name).to_s} - #{inserted_piece.try(:errors).try(:messages).to_s} - piece already exist")
            log_document = {
              name: "AccountingWorkflow::TempPackProcessor",
              erreur_type: "Piece already exist",
              date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
              more_information: {
                validation_model: temp_document.valid?,
                model: temp_document.inspect,
                user: temp_document.user.inspect,
                piece: temp_document.piece.inspect,
                temp_pack: temp_pack.inspect
              }
            }
            ErrorScriptMailer.error_notification(log_document).deliver
          end
        else
          temp_document.processed
        end

        if inserted_piece.try(:persisted?)
          if temp_document.api_name == 'invoice_auto'
            invoice_pieces << inserted_piece
          else
            added_pieces << inserted_piece
          end

          temp_document.processed
        elsif inserted_piece.present?
          LogService.info('document_processor', "[#{runner_id}] #{temp_pack.name.sub(' all', '')} (#{document_index+1}/#{temp_documents.size}) - n°#{temp_document.position} - #{inserted_piece.try(:name).to_s} - #{inserted_piece.try(:errors).try(:messages).to_s} - piece not persisted")
          log_document = {
            name: "AccountingWorkflow::TempPackProcessor",
            erreur_type: "Piece not persisted",
            date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
            more_information: {
              temp_document: temp_document.id,
              validation_model: inserted_piece.try(:errors).try(:messages).to_s
            }
          }
          ErrorScriptMailer.error_notification(log_document).deliver
        end

        LogService.info('document_processor', "[#{runner_id}] #{temp_pack.name.sub(' all', '')} (#{document_index+1}/#{temp_documents.size}) - n°#{temp_document.position} - #{temp_document.delivery_type} - #{temp_document.pages_number}p - end")
      end

    if recreate_original || is_locked
      log_document = {
        name: "AccountingWorkflow::TempPackProcessor",
        erreur_type: "Recreate bundle all document, pack ID : #{pack.id}",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          pack_name: pack.name,
          model: pack.inspect,
          recreate_original: recreate_original.to_s,
          is_locked: is_locked.to_s
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver

      Pack.delay_for(1.hours, queue: :low).try(:recreate_original_document, pack.id)
    end

    begin
      pack.original_document.cloud_content_object.attach(File.open(next_original_document), pack.pdf_name) if pack.original_document.save
    rescue
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
    pack.update(locked_at: nil)

    FileUtils.remove_entry dir if dir

    Reporting.update(pack)

    #Do not archive piece's files any more because of active storage
    # piece_files_path = (added_pieces + invoice_pieces).map { |e| e.cloud_content_object.path }
    # piece_files_path.in_groups_of(50).each do |group|
    #   DocumentTools.archive(pack.archive_file_path, group)
    # end

    if temp_pack.is_pre_assignment_needed?
      if user.validate_ibiza_analytics?
        added_pieces.each do |piece|
          if piece.from_web? || piece.from_mobile?
            piece.waiting_pre_assignment
          else
            piece.waiting_analytics_pre_assignment
          end
        end
      else
        added_pieces.each(&:waiting_pre_assignment)
      end

      AutoPreAssignedInvoicePieces.execute(invoice_pieces) if invoice_pieces.any?
    end

    FileDelivery.prepare(pack)

    published_temp_documents.each do |temp_document|
      NotifyPublishedDocument.new(temp_document).execute
    end
  end
end