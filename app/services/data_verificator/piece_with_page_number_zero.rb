# -*- encoding : UTF-8 -*-
class DataVerificator::PieceWithPageNumberZero < DataVerificator::DataVerificator
  def execute
    pieces = Pack::Piece.where("updated_at >= ? AND updated_at <= ? AND pages_number = ?", 1.days.ago, 1.hours.ago, 0)

    messages = []

    pieces.each do |piece|
      messages << "piece_id: #{piece.id}, piece_name: #{piece.name}"
    end

    {
      title: "PiecePageNumberZero - #{pieces.size} piece(s) with page number zero found",
      type: "table",
      message: messages.join('; ')
    }

  end 
end