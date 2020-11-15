class AddConnectorToRetriever < ActiveRecord::Migration[5.2]
  def change
    add_reference :retrievers, :connector, foreign_key: false
  end
end
