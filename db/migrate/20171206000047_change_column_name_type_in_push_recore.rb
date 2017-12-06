class ChangeColumnNameTypeInPushRecore < ActiveRecord::Migration[5.0]
  def up
  	rename_column :push_records, :type, :message_type
  end
end
