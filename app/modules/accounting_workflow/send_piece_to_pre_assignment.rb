class AccountingWorkflow::SendPieceToPreAssignment
  def self.execute(pieces)
    pieces.each do |piece|
      new(piece).execute unless piece.is_a_cover
    end
  end


  def initialize(piece)
    @piece = piece
  end


  def execute
    begin
      if @piece.temp_document.nil? || @piece.preseizures.any? || @piece.is_awaiting_pre_assignment?
        @piece.update(pre_assignment_state: 'ready') if @piece.pre_assignment_state == 'waiting'

        log_document = {
          subject: "[AccountingWorkflow::SendPieceToPreAssignment] re-init pre assignment state",
          name: "AccountingWorkflow::SendPieceToPreAssignment",
          error_group: "[accounting-workflow-send-piece-to-pre-assignment] re-init pre assignment state",
          erreur_type: "Re-init pre assignment state",
          date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          more_information: {
            piece_id: @piece.id,
            piece_name: @piece.name,
            temp_doc: @piece.temp_document.nil?,
            preseizures: @piece.preseizures.any?,
            piece:  @piece.inspect
          }
        }

        ErrorScriptMailer.error_notification(log_document).deliver

        return false
      end

      copy_to_dir manual_dir

      # @piece.update(is_awaiting_pre_assignment: true)

      @piece.processing_pre_assignment unless @piece.pre_assignment_force_processing?
    rescue => e
      System::Log.info('sending_to_preaff', "[Error] #{@piece.id} - #{@piece.name} - #{e.to_s}")
      return false
    end
  end


  private


  def manual_dir
    if journal.entry_type == 5
      list = AccountingWorkflow.pre_assignments_dir.join 'input', journal.compta_type, journal.user.organization.code
    else
      list = AccountingWorkflow.pre_assignments_dir.join 'input', journal.compta_type
    end
  end


  def journal
    @journal ||= @piece.user.account_book_types.where(name: @piece.journal).first
  end


  def is_taxable
    @is_taxable ||= @piece.user.options.is_taxable
  end


  def copy_to_dir(dir)
    FileUtils.mkdir_p(dir)

    detected_third_party_id = @piece.detected_third_party_id.presence || 6930

    _piece_name = @piece.pre_assignment_force_processing? ? "#{@piece.name.tr(' ', '_')}_recycle_#{detected_third_party_id}.pdf" : @piece.name.tr(' ', '_') + "_#{detected_third_party_id}" + '.pdf'

    POSIX::Spawn.system("cp #{@piece.temp_document.cloud_content_object.path} #{File.join(dir, _piece_name)}")
  end
end
