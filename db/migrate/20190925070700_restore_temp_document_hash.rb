class RestoreTempDocumentHash < ActiveRecord::Migration[5.2]
  def up
    ## Not use for now (find better way to get only 10000000 last records)
    # TempDocument.all.each do |i|
    #   retrieved_metadata = i.retrieved_metadata.to_s
    #   metadata = i.metadata.to_s

    #   i.retrieved_metadata = JSON.parse(retrieved_metadata.gsub('=>', ':').gsub('nil', 'null')).to_h
    #   i.metadata = JSON.parse(metadata.gsub('=>', ':').gsub('nil', 'null')).to_h

    #   i.save
    # end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
