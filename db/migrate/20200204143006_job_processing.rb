class JobProcessing < ActiveRecord::Migration[5.2]
  def change
  	create_table :job_processings do |t|
      t.string 	 :name
      t.datetime :started_at
      t.datetime :finished_at
      t.string 	 :state
      t.text 	   :notifications

    end
    add_index :job_processings, :name
    add_index :job_processings, :state
    add_index :job_processings, :finished_at
  end
end