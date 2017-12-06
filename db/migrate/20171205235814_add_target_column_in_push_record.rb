class AddTargetColumnInPushRecord < ActiveRecord::Migration[5.0]
  def change
  	add_column :push_records, :target_market, :string
  end
  def up
    change_column :push_records, :message_type, :string
  end

  def down
    change_column :push_records, :type, :string
  end
end
