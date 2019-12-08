class RestoreIbizaHash < ActiveRecord::Migration[5.2]
  class IbizaFix < ApplicationRecord
    self.table_name = 'ibizas'
    serialize :description
    serialize :piece_name_format
  end

  def up
    IbizaFix.all.each do |m|
      # Update this to match your real data and what you want `h` to be.
      pierce_name_format  = m.piece_name_format.to_unsafe_h.to_h
      m.piece_name_format = pierce_name_format

      description = m.description.to_unsafe_h.to_h
      m.description = description
      
      m.save!
    end
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