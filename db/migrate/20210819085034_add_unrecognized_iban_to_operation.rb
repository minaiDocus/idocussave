class AddUnrecognizedIbanToOperation < ActiveRecord::Migration[5.2]
  def change
    add_column :operations, :unrecognized_iban, :string

    add_index :operations, :unrecognized_iban
  end
end
