# A working spece for test nokogiri, will be deleted after things done
require 'open-uri'
require 'nokogiri'
require 'csv'
doc = Nokogiri::HTML(open("https://coinmarketcap.com/all/views/all/"))

nodeset = doc.css('tbody tr:not(.odd), tbody tr:not(.even)')
nodeset_len = nodeset.length

CSV.open("coinbase_test.csv", "w") do |csv|
   csv << ["ranking", "currency_name", "symbol", "market_cap", "price", "current_supply", "volumn", "hourly_change", "daily_change", "weekly_change"]

	nodeset.each do |block|
		block_set = block.children
		ranking = block_set[1].children.to_s.gsub(/\s+/, "")
		currency_name = block_set[3].children[5].children.to_s
		symbol = block_set[5].children.to_s
		market_cap = block_set[7].children.to_s.gsub(/\s+/, "").gsub(/,/, "").gsub(/\$/,"").to_f
		price = block_set[9].children.children.to_s.gsub(/,/, "").gsub(/\$/,"").to_f
		current_supply = block_set[11].children.children.to_s.gsub(/\s+/, "").gsub(/,/, "").gsub(/\$/,"").to_f
		volumn = block_set[13].children.children.to_s.gsub(/,/, "").gsub(/\$/,"").to_f
		hourly_change =  block_set[15].children.to_s.to_f
		daily_change = block_set[17].children.to_s.to_f
		weekly_change = block_set[19].children.to_s.to_f
		csv << [ranking, currency_name, symbol, market_cap, price, current_supply, volumn, hourly_change, daily_change, weekly_change]
	end
end