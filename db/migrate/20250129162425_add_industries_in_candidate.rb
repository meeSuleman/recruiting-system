class AddIndustriesInCandidate < ActiveRecord::Migration[7.2]
  def change
    add_column :candidates, :industries, :text, array: true, default: []
    add_index :candidates, :industries, using: :gin
  end
end
