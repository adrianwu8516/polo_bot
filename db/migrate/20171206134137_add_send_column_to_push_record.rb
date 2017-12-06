class AddSendColumnToPushRecord < ActiveRecord::Migration[5.0]
  def change
  	add_column :push_records, :status, :string
  end
end
