class SendPieceToPreAssignmentWorker
  include Sidekiq::Worker

  def perform
    UniqueJobs.for "SendPieceToPreAssignmentWorker" do
      Pack::Piece.need_preassignment.each do |piece|
        temp_pack = TempPack.find_by_name piece.pack.name

        if temp_pack.is_pre_assignment_needed? && !piece.is_a_cover
          AccountingWorkflow::SendPieceToPreAssignment.delay.execute([piece])
        else
          piece.ready_pre_assignment
        end
      end
    end
  end
end