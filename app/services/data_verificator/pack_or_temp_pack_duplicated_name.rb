# -*- encoding : UTF-8 -*-
class DataVerificator::PackOrTempPackDuplicatedName < DataVerificator::DataVerificator
  def execute
    packs = Pack.where(updated_at: [2.days.ago..Time.now]).group(:name).having('count(name) > 1').select(:name, :id).size
    temp_packs = TempPack.where(updated_at: [2.days.ago..Time.now]).group(:name).having('count(name) > 1').select(:name, :id).size

    messages = []

    packs.each {|name, count| messages << "pack: #{name}, count: #{count}" }
    temp_packs.each {|name, count| messages << "temp_pack: #{name}, count: #{count}" }

    {
      title: "PackOrTempPackDuplicatedName - #{packs.size + temp_packs.size} pack(s) or tempPack(s) duplicated name found",
      type: "table",
      message: messages.join('; ')
    }
  end
end