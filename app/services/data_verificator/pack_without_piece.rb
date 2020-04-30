# -*- encoding : UTF-8 -*-
class DataVerificator::PackWithoutPiece < DataVerificator::DataVerificator
  def execute
    packs = Pack.where("updated_at >= ? AND updated_at <= ?", 2.days.ago, Time.now)

    counter = 0

    messages = []

    packs.each do |pack|
      if pack.pieces.unscoped.where(pack_id: pack.id).count <= 0
        counter += 1
        messages << "#{pack.id} - #{pack.name}"
      end
    end

    {
      title: "PackWithoutPiece - #{counter} pack(s) without piece found",
      message: messages.join('; ')
    }
  end
end