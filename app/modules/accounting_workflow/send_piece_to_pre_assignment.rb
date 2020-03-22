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
    return false if @piece.temp_document.nil? || @piece.preseizures.any? || @piece.is_awaiting_pre_assignment

    copy_to_dir manual_dir

    @piece.update(is_awaiting_pre_assignment: true)

    @piece.processing_pre_assignment unless @piece.pre_assignment_force_processing?
  end


  private


  def manual_dir
    list = AccountingWorkflow.pre_assignments_dir.join 'input', journal.compta_type
  end


  def journal
    @journal ||= @piece.user.account_book_types.where(name: @piece.journal).first
  end


  def is_taxable
    @is_taxable ||= @piece.user.options.is_taxable
  end


  def copy_to_dir(dir)
    FileUtils.mkdir_p(dir)

    _piece_name = @piece.pre_assignment_force_processing? ? "#{@piece.name.tr(' ', '_')}_recycle.pdf" : @piece.name.tr(' ', '_') + "-#{@piece.detected_third_party_id}" + '.pdf'

    POSIX::Spawn.system("cp #{@piece.temp_document.cloud_content_object.path} #{File.join(dir, _piece_name)}")
  end
end
