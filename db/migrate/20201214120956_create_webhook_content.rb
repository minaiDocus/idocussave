class CreateWebhookContent < ActiveRecord::Migration[5.2]
  def change
    create_table :archive_webhook_contents do |t|
      t.datetime :synced_date
      t.string :synced_type
      t.text :json_content
      t.integer :retriever_id

      t.timestamps
    end
  end
end
