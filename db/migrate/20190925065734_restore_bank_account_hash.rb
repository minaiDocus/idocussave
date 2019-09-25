class RestoreBankAccountHash < ActiveRecord::Migration[5.2]
  def up
    BankAccount.all.each do |i|
      original_currency = i.original_currency.to_s

      i.original_currency = JSON.parse(original_currency.gsub('=>', ':').gsub('nil', 'null')).to_h

      i.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
