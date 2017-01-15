class RenameFiduceoProviderWishesToNewProviderRequests < ActiveRecord::Migration
  def change
    rename_table :fiduceo_provider_wishes, :new_provider_requests
  end
end
