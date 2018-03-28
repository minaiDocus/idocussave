class AddIndexToGroups < ActiveRecord::Migration
  def change
    add_index "groups_users", "user_id"
    add_index "groups_users", "group_id"
    add_index "groups_members", "group_id"
    add_index "groups_members", "member_id"
  end
end
