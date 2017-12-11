class AddColumnToMarketCapToShowIfExpired < ActiveRecord::Migration[5.0]
  def change
  	add_column :coinmarketcaps, :expired, :boolean
  end
end
