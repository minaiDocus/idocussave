class ChangePathDefaultForBoxes < ActiveRecord::Migration
  def change
    change_column_default :boxes, :path, 'iDocus/:code/:year:month/:account_book'
  end
end
