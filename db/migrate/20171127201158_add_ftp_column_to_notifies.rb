class AddFtpColumnToNotifies < ActiveRecord::Migration
  def change
    add_column :notifies, :ftp_auth_failure, :boolean, default: true, after: :dropbox_insufficient_space
  end
end
