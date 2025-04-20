class AddIndexToCandidates < ActiveRecord::Migration[7.2]
  def change
    add_index :candidates, :experience
    add_index :candidates, :function
    add_index :candidates, :city
    add_index :candidates, :institute
    add_index :candidates, :created_at  # Also adding this for date filtering
  end
end
