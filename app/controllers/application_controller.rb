class ApplicationController < ActionController::Base

	protect_from_forgery with: :exception

	attr_reader :currencies

	require 'history_info'
	require 'ticker_info'
	require 'market_volume'

	helper_method :getTickerPair, :getMarketVolumn, :HistoryInfo

	def initinlize
		currencies = JSON.parse(Poloniex.get('returnCurrencies')).keys
	end

	def getTickerPair(currency_A, currency_B)
		currency_pair = currency_A + '_' + currency_B
		target_json = JSON.parse(Poloniex.ticker)[currency_pair]
		return TickerInfo.new(target_json)
	end

	def getMarketVolumn
		return MarketVolume.new
	end

	def getHistoryInfoPair(currency_A, currency_B, period_sec, period_num)
		# period_sec can only be 300, 900, 1800, 7200, 14400, 86400
		currency_pair = currency_A + '_' + currency_B
		histroy_json = JSON.parse(Poloniex.get('returnChartData',{currencyPair:currency_pair, period: period_sec, start: (Time.now.to_i - period_sec*period_num) ,:end =>Time.now.to_i}))
		HistoryInfo.new(histroy_json)
	end

 # HisteryInfo('USDT_BTC', 86400, 7)
 #t = TickerInfo.new(JSON.parse(Poloniex.ticker)["USDT_BTC"])
# Poloniex.get('returnChartData',{currencyPair:'USDT_BTC', period: 86400, start: (Time.now.to_i - 86400*7) ,:end =>Time.now.to_i})

end
