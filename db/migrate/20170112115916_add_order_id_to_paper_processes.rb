class AddOrderIdToPaperProcesses < ActiveRecord::Migration
  def change
    add_reference :paper_processes, :order, index: true
  end
end
