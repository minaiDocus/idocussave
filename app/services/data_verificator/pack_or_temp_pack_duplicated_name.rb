# -*- encoding : UTF-8 -*-
class DataVerificator::PackOrTempPackDuplicatedName < DataVerificator::DataVerificator
  def execute
    packs = Pack.where(updated_at: [2.days.ago..Time.now]).group(:name).having('count(name) > 1').select(:name, :id).size
    temp_packs = TempPack.where(updated_at: [2.days.ago..Time.now]).group(:name).having('count(name) > 1').select(:name, :id).size

    messages = []

    packs.each {|name, count| messages << "Pack: #{name} => #{count}" }
    temp_packs.each {|name, count| messages << "TempPack: #{name} => #{count}" }

    {
      title: "PackOrTempPackDuplicatedName - #{packs.size + temp_packs.size} pack(s) or tempPack(s) duplicated name found",
      message: messages.join('; ')
    }
  end
end