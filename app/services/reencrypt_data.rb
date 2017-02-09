# Used when rotating encryption key
# Decrypt with the old key et re-encrypt with the new key
class ReencryptData
  def self.execute
    list = [
      [BudgeaAccount, [:access_token]],
      [Retriever,     [:param1, :param2, :param3, :param4, :param5, :answers]]
    ]

    list.each do |klass, attributes|
      puts klass
      klass.all.each do |entry|
        attributes.each do |attribute|
          entry.send("#{attribute}=", entry.send(attribute))
        end
        entry.save
        print '.'
      end
      print "\n"
    end

    true
  end
end
