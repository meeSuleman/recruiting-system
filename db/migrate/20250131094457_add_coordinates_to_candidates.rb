class AddCoordinatesToCandidates < ActiveRecord::Migration[7.2]
  def change
    add_column :candidates, :latitude, :float
    add_column :candidates, :longitude, :float
    add_index :candidates, [ :latitude, :longitude ]
  end
end
