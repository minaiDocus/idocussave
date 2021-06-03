# -*- encoding : UTF-8 -*-
class DataVerificator::PieceReadyTempPackPreAssignmentNeeded < DataVerificator::DataVerificator
  def execute
    pieces = Pack::Piece.where(pre_assignment_state: 'ready', is_a_cover: false, created_at: [2.days.ago..Time.now]).order(created_at: :desc)

    messages = []
    pieces.each do |pi|
      tp = TempPack.find_by_name(pi.pack.name)
      messages << "piece_id: #{pi.id}, piece_name: #{pi.name}, temp_pack_name: #{tp.name.to_s}" if tp.try(:is_compta_processable?) && pi.preseizures.size == 0
    end

    {
      title: "Piece ready with is_compta_processable state, count = #{messages.size}",
      type: "table",
      message: messages.join('; ')
    }
  end
end