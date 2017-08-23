class AddPortAndIsPassiveToFtps < ActiveRecord::Migration
  def change
    add_column :ftps, :encrypted_port, :string
    add_column :ftps, :is_passive, :boolean, default: true

    Ftp.all.each do |ftp|
      ftp.update(port: 21)
    end
  end
end
