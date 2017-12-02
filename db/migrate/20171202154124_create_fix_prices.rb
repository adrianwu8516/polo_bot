class CreateFixPrices < ActiveRecord::Migration[5.0]
  def change
    create_table :fix_prices do |t|
      t.string :lineuser_id
      t.string :currency_pair
      t.string :logic
      t.float :setting_price
      t.string :status, default: "ON"
      t.timestamps
    end
  end
end
