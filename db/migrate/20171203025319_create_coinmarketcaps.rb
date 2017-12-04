class CreateCoinmarketcaps < ActiveRecord::Migration[5.0]
  def change
    create_table :coinmarketcaps do |t|
      t.integer :ranking
      t.string :currency_name
      t.string :symbol
      t.string :market_cap
      t.float :price
      t.float :current_supply
      t.float :volumn
      t.float :hourly_change
      t.float :daily_change
      t.float :weekly_change
      t.timestamps
    end
  end
end
