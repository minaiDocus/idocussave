class RestoreOperationHash < ActiveRecord::Migration[5.2]
  def up
    Operation.all.each do |i|
      currency = i.currency.to_s
      i.currency = JSON.parse(currency.gsub('=>', ':').gsub('nil', 'null')).to_h
      i.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
