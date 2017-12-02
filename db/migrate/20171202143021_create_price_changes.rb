class CreatePriceChanges < ActiveRecord::Migration[5.0]
  def change
    create_table :price_changes do |t|
      t.string :lineuser_id
      t.string :currency_pair
      t.integer :period_sec, default: 300
      t.integer :period_num, default: 2
      t.float :range, default: 0.03
      t.string :status, default: "ON"
      t.timestamps
    end
  end
end
