require 'open-uri'
require 'nokogiri'
require 'csv'

def parsingCoinbase
	doc = Nokogiri::HTML(open("https://coinmarketcap.com/all/views/all/"))
	puts "Parsing items..." + Time.current.to_s
	return doc.css('tbody tr:not(.odd), tbody tr:not(.even)')
end

def parsingCoingecko
	return_array = Array.new
	return_array.push(Nokogiri::HTML(open("https://www.coingecko.com/en?sort_by=market_cap")).css('tbody tr'))
	return_array.push(Nokogiri::HTML(open("https://www.coingecko.com/en?page=2&sort_by=market_cap")).css('tbody tr'))
	return_array.push(Nokogiri::HTML(open("https://www.coingecko.com/en?page=3&sort_by=market_cap")).css('tbody tr'))
	return_array.push(Nokogiri::HTML(open("https://www.coingecko.com/en?page=4&sort_by=market_cap")).css('tbody tr'))
	return_array.push(Nokogiri::HTML(open("https://www.coingecko.com/en?page=5&sort_by=market_cap")).css('tbody tr'))
	puts "Parsing items..." + Time.current.to_s
	return return_array
end


def recordCoingeckoToDataBase
	Coingecko.where(expired: nil).update(expired: true)
	docs = parsingCoingecko
	docs.each do |doc|
		doc.each do |block|
			block_set = block.children
			ranking = block_set[1].children.to_s.gsub(/\s+/, "").to_i
			currency_name = block_set[3].children[1].children[3].children[1].children[1].children.to_s
			symbol = block_set[3].children[1].children[3].children[1].children[3].children.to_s
			market_cap = block_set[7].children[1].children[1].children.to_s.gsub(/\s+/, "").gsub(/,/, "").gsub(/\$/,"").to_f
			liquidity = block_set[9].children[1].children[0].to_s.gsub(/\s+/, "").gsub(/,/, "").gsub(/\$/,"").to_f
			developer_index = block_set[11].children[1].children[0].to_s.gsub(/\s+/, "").to_f
			community_index = block_set[13].children[1].children[0].to_s.gsub(/\s+/, "").to_f
			public_index = block_set[15].children[1].children[0].to_s.gsub(/\s+/, "").to_f
			total = block_set[17].children[0].children.to_s.gsub(/\s+/, "").to_f
			url = "https://www.coingecko.com/en/price_charts/"+currency_name.downcase+"/usd#panel"
			Coingecko.create(
				ranking: ranking,
				currency_name: currency_name,
				symbol: symbol,
				market_cap: market_cap,
				liquidity: liquidity,
				developer_index: developer_index,
				community_index: community_index,
				public_index: public_index,
				total: total,
				url: url)
		end
	end
end

def outputCSVfile
	CSV.open("coinbase_test.csv", "w") do |csv|
	   	csv << ["ranking", "currency_name", "symbol", "market_cap", "price", "current_supply", "volumn", "hourly_change", "daily_change", "weekly_change"]
		nodeset.each do |block|
			block_set = block.children
			ranking = block_set[1].children.to_s.gsub(/\s+/, "").to_i
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
end

def recordCoinbaseToDataBase
	# Mark old data to be expired
	Coinmarketcap.where(expired: nil).update(expired: true)
	nodeset = parsingCoinbase
	puts "recording... " + nodeset.length.to_s + " items"
	nodeset.each do |block|
		block_set = block.children
		ranking = block_set[1].children.to_s.gsub(/\s+/, "").to_i
		currency_name = block_set[3].children[5].children.to_s
		symbol = block_set[5].children.to_s
		market_cap = block_set[7].children.to_s.gsub(/\s+/, "").gsub(/,/, "").gsub(/\$/,"").to_f
		price = block_set[9].children.children.to_s.gsub(/,/, "").gsub(/\$/,"").to_f
		current_supply = block_set[11].children.children.to_s.gsub(/\s+/, "").gsub(/,/, "").gsub(/\$/,"").to_f
		volumn = block_set[13].children.children.to_s.gsub(/,/, "").gsub(/\$/,"").to_f
		hourly_change =  block_set[15].children.to_s.to_f
		daily_change = block_set[17].children.to_s.to_f
		weekly_change = block_set[19].children.to_s.to_f
		Coinmarketcap.create(
			ranking: ranking,
			currency_name: currency_name,
			symbol: symbol,
			market_cap: market_cap,
			price: price,
			current_supply: current_supply,
			volumn: volumn,
			hourly_change: hourly_change,
			daily_change: daily_change,
			weekly_change: weekly_change
		)
	end
end



namespace :regular do
    desc "每天抓取市場資料"
    task :coinmarketcapToday => :environment do
    	recordCoinbaseToDataBase
    	recordCoingeckoToDataBase
    	puts "Job's done" + Time.current.to_s
    end
end