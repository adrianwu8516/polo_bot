class CreateCoingeckos < ActiveRecord::Migration[5.0]
  def change
    create_table :coingeckos do |t|
    	t.integer  "ranking"
    	t.string   "currency_name"
    	t.string   "symbol"
    	t.float    "market_cap"
    	t.float    "liquidity"
    	t.float    "developer_index"
    	t.float    "community_index"
    	t.float    "public_index"
    	t.float    "total"
    	t.string   "url"
    	t.boolean  "expired"
      	t.timestamps
    end
  end
end