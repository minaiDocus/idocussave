# -*- encoding : UTF-8 -*-
class DataVerificator::TempPackWithoutTempDocument < DataVerificator::DataVerificator
  def execute
    temp_packs = TempPack.where("updated_at >= ? AND updated_at <= ?", 2.days.ago, Time.now)

    counter = 0
 
    messages = []

    temp_packs.each do |temp_pack|
      if temp_pack.temp_documents.empty?
        counter += 1
        messages << "temp_pack_id: #{temp_pack.id}, temp_pack_name: #{temp_pack.name}"
      end
    end

    {
      title: "TempPackWithoutTempDocument - #{counter} tempPack(s) without tempDocument found",
      type: "table",
      message: messages.join('; ')
    }
  end
end