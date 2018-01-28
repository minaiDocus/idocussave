class CreateNews < ActiveRecord::Migration
  def change
    create_table :news do |t|
      t.column :state, :string, null: false
      t.column :title, :string, null: false
      t.column :body, :text, null: false
      t.column :target_audience, :string, null: false, index: true
      t.column :url, :string
      t.column :published_at, :datetime, index: true

      t.timestamps null: false
    end

    add_column :users, :news_read_at, :datetime, index: true
  end
end
