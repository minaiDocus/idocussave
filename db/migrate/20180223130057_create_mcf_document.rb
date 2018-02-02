class CreateMcfDocument < ActiveRecord::Migration
  def change
    create_table :mcf_documents do |t|
      t.references  :user, index: true

      t.string      :access_token
      t.string      :code
      t.string      :journal
      t.string      :original_file_name, default: ''
      t.text        :file64, limit: 4294967295
      t.string      :state, default: 'ready'
      
      t.integer     :retake_retry, default: 0
      t.datetime    :retake_at, default: nil
      
      t.boolean     :is_generated, default: false
      t.boolean     :is_moved, default: false
      t.boolean     :is_notified, default: false
      
      t.text        :error_message, default: nil
      
      t.datetime    :updated_at
      t.datetime    :created_at
    end
  end
end
