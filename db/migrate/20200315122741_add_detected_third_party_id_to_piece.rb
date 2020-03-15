class AddDetectedThirdPartyIdToPiece < ActiveRecord::Migration[5.2]
  def change
    add_column :pack_pieces, :detected_third_party_id, :integer
  end
end
