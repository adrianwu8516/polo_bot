class ApplicationController < ActionController::Base

	protect_from_forgery with: :exception

	attr_reader :currencies

	require 'history_info'
	require 'ticker_info'
	require 'market_volume'

	helper_method :getTicker, :getMarketVolumn, :HistoryInfo

	def initinlize
		currencies = JSON.parse(Poloniex.get('returnCurrencies')).keys
	end

	def getTicker(symbol)
		currency_pair = 'USDT_' + symbol
		target_json = JSON.parse(Poloniex.ticker)[currency_pair]
		return TickerInfo.new(target_json)
	end

	def getMarketVolumn
		return MarketVolume.new
	end

	def HistoryInfo(currency_pair, period_sec, period_num)
		histroy_json = JSON.parse(Poloniex.get('returnChartData',{currencyPair:currency_pair, period: period_sec, start: (Time.now.to_i - period_sec*period_num) ,:end =>Time.now.to_i}))
		HistoryInfo.new(histroy_json)
	end

 # HisteryInfo('USDT_BTC', 86400, 7)
 #t = TickerInfo.new(JSON.parse(Poloniex.ticker)["USDT_BTC"])
# Poloniex.get('returnChartData',{currencyPair:'USDT_BTC', period: 86400, start: (Time.now.to_i - 86400*7) ,:end =>Time.now.to_i})

end
