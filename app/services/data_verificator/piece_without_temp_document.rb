# -*- encoding : UTF-8 -*-
class DataVerificator::PieceWithoutTempDocument < DataVerificator::DataVerificator
  def execute
    pieces = Pack::Piece.where("updated_at >= ? AND updated_at <= ?", 2.days.ago, Time.now)

    counter = 0
 
    messages = []

    pieces.each do |piece|
      if piece.temp_document.nil?
        counter += 1
        messages << "#{piece.id} - #{piece.name}"
      end
    end

    {
      title: "PieceWithoutTempDocument - #{counter} piece(s) without tempDocument found",
      message: messages.join('; ')
    }
  end
end