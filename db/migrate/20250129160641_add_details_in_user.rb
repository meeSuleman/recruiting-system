class AddDetailsInUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :contact, :string
    add_column :users, :role, :string
    add_column :users, :invite_status, :string
    add_column :users, :is_active, :boolean, default: true
  end
end
