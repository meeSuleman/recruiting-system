class AddCandidateTable < ActiveRecord::Migration[7.2]
  def change
    create_table :candidates do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :contact_number, null: false
      t.datetime :dob, null: false
      t.integer :education, null: false
      t.integer :experience, null: false
      t.string :expected_salary, null: false
      t.string :career_phase, null: false
      t.string :additional_notes
      t.string :institute
      t.boolean :currently_employed, default: false
      t.string :current_salary
      t.string :current_employer
      t.integer :function
      t.string :address
      t.string :city
      t.string :state
      t.timestamps
    end
  end
end
