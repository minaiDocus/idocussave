class RestoreIbizaHash < ActiveRecord::Migration[5.2]
  def up
    Ibiza.all.each do |i|
      piece_name_format = i.piece_name_format.to_s
      description = i.description.to_s

      i.piece_name_format = JSON.parse(piece_name_format.gsub('=>', ':').gsub('nil', 'null')).to_h
      i.description = JSON.parse(description.gsub('=>', ':').gsub('nil', 'null')).to_h

      i.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end