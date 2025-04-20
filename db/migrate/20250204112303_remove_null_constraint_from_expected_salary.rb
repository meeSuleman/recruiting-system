class RemoveNullConstraintFromExpectedSalary < ActiveRecord::Migration[7.2]
  def change
    change_column_null :candidates, :expected_salary, true
  end
end
