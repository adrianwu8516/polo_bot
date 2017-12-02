def getTickerPair(currency_pair)
	target_json = JSON.parse(Poloniex.ticker)[currency_pair]
	return TickerInfo.new(target_json)
end

def getMarketVolumn
	return MarketVolume.new
end

def getTradingCurrencies
	return JSON.parse(Poloniex.volume).keys
end

def getHistoryInfoPair(currency_pair, period_sec, period_num)
	# period_sec can only be 300, 900, 1800, 7200, 14400, 86400
	histroy_json = JSON.parse(Poloniex.get('returnChartData',{currencyPair:currency_pair, period: period_sec, start: (Time.now.to_i - period_sec*period_num) ,:end =>Time.now.to_i}))
	return HistoryInfo.new(histroy_json)
end

def getCurrencies
	array = Array.new
	getTradingCurrencies.grep(/_/).each do |pair|
		currency_B = pair.split("_")[1]
		if array.exclude? currency_B
			array.push(currency_B)
		end
	end
	return array
end

def pairGenerator(unknown_str)
	unknown_str_array = unknown_str.split('_')
	if unknown_str_array.length == 2
		currency_a = unknown_str_array[0]
		currency_b = unknown_str_array[1]
		if currency_b == 'USDT'
			return currency_b+'_'+currency_a
		elsif currency_b == 'BTC' && currency_a != 'USDT'
			return currency_b+'_'+currency_a
		elsif currency_b == 'ETH' && currency_a != 'USDT' &&  currency_a != 'BTC'
			return currency_b+'_'+currency_a
		elsif currency_b == 'XMR'&& currency_a != 'USDT' &&  currency_a != 'BTC'
			return currency_b+'_'+currency_a
		else
			return currency_a+'_'+currency_b
		end
	else
		return unknown_str
	end
end

def getTradingCurrencies_single(currency)
	array = Array.new
	getTradingCurrencies.each do |pair|
		if pair.split("_").include? currency
			array.push(pair)
		end
	end
	return array
end

def getReadablePair(currency_pair)
	currency_pair = currency_pair.split('_')
	return currency_pair[1]+' to '+currency_pair[0]
end