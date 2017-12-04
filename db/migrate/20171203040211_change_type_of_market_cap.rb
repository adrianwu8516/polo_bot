class ChangeTypeOfMarketCap < ActiveRecord::Migration[5.0]
  def up
    change_column :coinmarketcaps, :market_cap, :float
  end

  def down
    change_column :coinmarketcaps, :market_cap, :string
  end
end
