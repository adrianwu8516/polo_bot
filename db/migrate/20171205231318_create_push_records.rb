class CreatePushRecords < ActiveRecord::Migration[5.0]
  def change
    create_table :push_records do |t|
      t.string :content
      t.string :type
      t.string :news_date
      t.timestamps
    end
  end
end
