class AddExpiresAtToInvitations < ActiveRecord::Migration[7.2]
  def change
    add_column :invitations, :expires_at, :datetime
  end
end
