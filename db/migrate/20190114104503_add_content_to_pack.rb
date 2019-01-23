class AddContentToPack < ActiveRecord::Migration
  def change
    add_column :packs, :content_file_name, :string
    add_column :packs, :content_content_type, :string
    add_column :packs, :content_file_size, :integer,  limit: 4
    add_column :packs, :content_updated_at, :datetime
    add_column :packs, :content_fingerprint, :string
  end
end
