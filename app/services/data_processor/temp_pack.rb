# -*- encoding : UTF-8 -*-
class DataProcessor::TempPack
  POSITION_SIZE = 3

  def self.process(temp_pack_name)
    UniqueJobs.for "PublishDocument-#{temp_pack_name}", 2.hours, 2 do
      temp_pack = TempPack.find_by_name temp_pack_name
      execute(temp_pack)
      sleep(60) #lock multi temp pack processing to avoid access disk overload
    end
  end

  def self.execute(temp_pack)
    return false unless temp_pack.not_processed?

    new(temp_pack).execute
  end

  def self.unblock_temp_doc(temp_doc_id)
    temp_document = TempDocument.find temp_doc_id

    return false if temp_document.corruption_notified_at.present?

    temp_document.corruption_notified_at = Time.now
    temp_document.state = 'ready'
    temp_document.save
  end

  def initialize(temp_pack)
    @temp_pack      = temp_pack
    @temp_documents = temp_pack.ready_documents
    @user           = temp_pack.user
  end

  def execute
    return false if @temp_documents.empty? || !@user

    @original_doc_merged = true
    sleep_counter = 5

    CustomUtils.mktmpdir('temp_pack_processor') do |dir|
      @dir = dir
      prepare_original_document #For appending or prepending bundled document

      @temp_documents.each do |temp_document|
        #add a sleeping time to prevent disk access overload
        sleep_counter -= 1
        if sleep_counter <= 0
          sleep(7)
          sleep_counter = 5
        end

        @is_a_cover = temp_document.is_a_cover?

        if @is_a_cover && pack.has_cover?
          temp_document.processed
          next
        end
        if !File.exist?(temp_document.cloud_content_object.path.to_s)
          sleep(15)
          if !File.exist?(temp_document.cloud_content_object.reload.path.to_s)
            log_document = {
              subject: "[DataProcessor::TempPack] - Unreadable temp_document",
              name: "DataProcessor::TempPack",
              error_group: "[data_processor-temp_pack] unreadable temp_document",
              erreur_type: "Unreadable temp document : #{temp_document.id}",
              date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
              more_information: {
                temp_document: temp_document.inspect,
                path: temp_document.cloud_content_object.reload.path.to_s
              }
            }

            ErrorScriptMailer.error_notification(log_document, { unlimited: true }).deliver

            temp_document.unreadable
            DataProcessor::TempPack.delay_for(1.hours, queue: :low).unblock_temp_doc(temp_document.id)
            next
          end
        end

        if create_or_update_piece_with(temp_document)
          create_dividers_with(temp_document)

          create_pages_with(temp_document)

          merge_original_document

          prepare_piece_for_pre_assignment

          temp_document.processed
        end
      end

      finalize_pack

      Reporting.update(pack)

      FileDelivery.prepare(pack)

      Pack.delay(queue: :low).store_archive_of(pack.id)
    end
  end

  private

  def pack
    return @new_pack if @new_pack

    @new_pack = Pack.find_or_initialize @temp_pack.name, @user
  end

  def basename
    pack.name.sub(' all', '')
  end

  def need_pre_assignment?
    return @need_pre_assignment unless @need_pre_assignment.nil?

    @need_pre_assignment = @temp_pack.is_compta_processable?
  end

  def uses_analytics?
    return @uses_analytics unless @uses_analytics.nil?

    @uses_analytics = @user.validate_ibiza_analytics?
  end

  def next_piece_position
    return 0 if @is_a_cover

    if @piece_position.to_i > 0
      @piece_position = @piece_position + 1
    else
      @piece_position =   begin
                           pack.pieces.unscoped.where(pack_id: pack.id).by_position.last.position + 1
                          rescue
                           1
                          end
    end

    @piece_position
  end

  def next_page_position
    return 0 if @is_a_cover

    if @page_position.to_i > 0
      @page_position = @page_position + 1
    else
      @page_position =  begin
                          pack.pages.by_position.last.position + 2
                        rescue
                          1
                        end
    end
  end

  def prepare_original_document
    @next_original_document = pack.original_document.cloud_content_object.path.to_s
    @next_original_document = File.join(@dir, "next_original_#{Time.now.strftime('%Y%m%d%H%M%S')}.pdf") if !File.exist?(@next_original_document)

    @pack_locked = pack.is_locked?
    pack.update(locked_at: Time.now)
  end

  def merge_original_document
    if @original_doc_merged && pack.original_document.present?
      if !@pack_locked
        if pack.original_document.cloud_content_object.size.to_i < 400.megabytes
          if @is_a_cover
            pack.prepend @piece_file_path, @dir, @next_original_document
          else
            @original_doc_merged = false if !pack.append(@piece_file_path, @dir, @next_original_document)
          end
        else
          @original_doc_merged = false
        end
      end

      if !@original_doc_merged || @pack_locked
        log_document = {
          subject: "[DataProcessor::TempPack] recreate bundle all document pack id #{pack.id}",
          name: "DataProcessor::TempPack",
          error_group: "[datap_rocessor-temp_pack] recreate bundle all document pack id",
          erreur_type: "Recreate bundle all document, pack ID : #{pack.id}",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            pack_name: pack.name,
            model: pack.inspect,
            original_doc_merged: @original_doc_merged.to_s,
            is_locked: @pack_locked.to_s
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver

        Pack.delay_for(1.hours, queue: :low).recreate_original_document(pack.id)

        @original_doc_merged = false #Avoid multiple merging when original_doc_merged or pack_locked once detected
      end
    end
  end

  def finalize_pack
    begin
      pack.original_document.cloud_content_object.attach(File.open(@next_original_document), pack.pdf_name) if @original_doc_merged && pack.original_document.save
    rescue
    end

    pack.set_original_document_id
    pack.set_content_url
    pack.set_pages_count
    pack.set_historic
    pack.set_tags
    pack.is_update_notified = false
    pack.locked_at = nil
    pack.is_fully_processed = true if @temp_pack.reload && @temp_pack.bundle_needed_count == 0

    pack.save
  end

  def create_or_update_piece_with(temp_document)
    current_piece_position = next_piece_position
    piece_name = DocumentTools.name_with_position(basename, current_piece_position, POSITION_SIZE)

    @inserted_piece = temp_document.piece.presence || Pack::Piece.unscoped.where(name: piece_name).first

    piece = @inserted_piece || Pack::Piece.new

    return false if @inserted_piece.try(:temp_document) && @inserted_piece.temp_document.id != temp_document.id

    if !@inserted_piece
      piece.organization          = @user.organization
      piece.user                  = @user
      piece.pack                  = pack
      piece.name                  = piece_name
      piece.position              = current_piece_position
    end

    piece.is_a_cover            = @is_a_cover
    piece.origin                = temp_document.delivery_type
    piece.temp_document         = temp_document
    piece.analytic_reference_id = temp_document.analytic_reference_id

    if piece.save
      @inserted_piece = piece
      temp_document.save

      begin
        @piece_file_path = @inserted_piece.reload.recreate_pdf(@dir)
        true
      rescue => e
        log_document = {
          subject: "[DataProcessor::TempPack] piece file not generated #{e.message}",
          name: "DataProcessor::TempPack",
          error_group: "[data_processor-temp_pack] piece file not generated",
          erreur_type: "Piece file not generated",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            temp_document: temp_document.id,
            error: e.to_s,
            piece: piece.inspect,
            validation_model: piece.try(:errors).try(:messages).to_s
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver

        false
      end
    else
      log_document = {
        subject: "[DataProcessor::TempPack] piece not saved",
        name: "DataProcessor::TempPack",
        error_group: "[data_processor-temp_pack] piece not saved",
        erreur_type: "Piece not saved",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          temp_document: temp_document.id,
          validation_model: piece.try(:errors).try(:messages).to_s
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver

      false
    end
  end

  def create_dividers_with(temp_document)
    pack_divider              = pack.dividers.where(position: @inserted_piece.position, type: 'piece').first || pack.dividers.build
    pack_divider.type         = 'piece'
    pack_divider.origin       = temp_document.delivery_type
    pack_divider.is_a_cover   = @is_a_cover
    pack_divider.name         = DocumentTools.file_name(@inserted_piece.name).sub('.pdf', '')
    pack_divider.pages_number = @inserted_piece.pages_number
    pack_divider.position     = @inserted_piece.position
    pack_divider.save

    if temp_document.scanned?
      position        = pack.dividers.sheets.not_covers.last.try(:position) || 0
      position        = @is_a_cover ? 0 : (position + 1)
      base_file_name  = basename.tr(' ', '_')

      if @temp_pack.is_compta_processable?
        temp_document.scan_bundling_document_ids.each do |id|
          bundling_document         = TempDocument.find(id)

          pack_divider              = pack.dividers.build
          pack_divider.pack         = pack
          pack_divider.type         = 'sheet'
          pack_divider.origin       = temp_document.delivery_type
          pack_divider.is_a_cover   = @is_a_cover
          pack_divider.name         = base_file_name + "_%0#{POSITION_SIZE}d" % position
          pack_divider.pages_number = bundling_document.pages_number
          pack_divider.position     = position
          pack_divider.save
          position += 1
        end
      else
        pack_divider              = pack.dividers.where(position: position, type: 'sheet').first || pack.dividers.build
        pack_divider.pack         = pack
        pack_divider.type         = 'sheet'
        pack_divider.origin       = temp_document.delivery_type
        pack_divider.is_a_cover   = @is_a_cover
        pack_divider.name         = base_file_name + "_%0#{POSITION_SIZE}d" % position
        pack_divider.pages_number = @inserted_piece.pages_number
        pack_divider.position     = position
        pack_divider.save
      end
    end
  end

  def create_pages_with(temp_document)
    if pack.has_documents?
      suffix = @is_a_cover ? 'cover_page' : 'page'

      Pdftk.new.burst @piece_file_path, @dir, suffix, POSITION_SIZE

      Dir.glob("#{@dir}/#{suffix}_*.pdf").sort.each_with_index do |file_path, index|
        current_page_position = next_page_position

        position = @is_a_cover ? (index + 1) : current_page_position

        page_name = DocumentTools.name_with_position(basename + " #{suffix}", position, POSITION_SIZE)
        page_file_name = DocumentTools.file_name(page_name)
        page_file_path = File.join(@dir, page_file_name)
        page_file_signed_path = File.join(@dir, page_file_name.gsub('.pdf', '_signed.pdf'))
        FileUtils.mv file_path, page_file_path

        page                = Document.new
        page.pack           = pack
        page.position       = @is_a_cover ? (index - 2) : (current_page_position - 1)
        page.origin         = temp_document.delivery_type
        page.is_a_cover     = @is_a_cover

        DocumentTools.sign_pdf(page_file_path, page_file_signed_path) unless temp_document.api_name == 'jefacture'
        page.cloud_content_object.attach(File.open(page_file_signed_path), page_file_name) if page.save
      end
    end
  end

  def prepare_piece_for_pre_assignment
    if need_pre_assignment?
      if @inserted_piece.temp_document.api_name == 'invoice_auto'
        PreAssignment::AutoPreAssignedInvoicePieces.execute([@inserted_piece])
      elsif @inserted_piece.temp_document.api_name == 'jefacture'
        SgiApiServices::AutoPreAssignedJefacturePiecesValidation.execute([@inserted_piece])
        # AccountingWorkflow::SendPieceToSupplierRecognition.execute([@inserted_piece]) if not success
      else
        Pack::Piece.extract_content(@inserted_piece)

        if uses_analytics?
          if @inserted_piece.from_web? || @inserted_piece.from_mobile?
            AccountingWorkflow::SendPieceToSupplierRecognition.execute([@inserted_piece])
          else
            @inserted_piece.waiting_analytics_pre_assignment
          end
        else
          AccountingWorkflow::SendPieceToSupplierRecognition.execute([@inserted_piece])
        end
      end
    end
  end
end
