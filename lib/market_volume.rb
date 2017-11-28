class MarketVolume
	attr_reader :see_specific, :BTC, :ETH, :USDT, :XMR, :XUSD

	def initialize
		@volume_json = JSON.parse(Poloniex.volume)
	end

	def see_specific(currency_pair)
		return @volume_json[currency_pair]
	end

	def BTC
		return @volume_json["totalBTC"].to_f
	end

	def ETH
		return @volume_json["totalETH"].to_f
	end

	def USDT
		return @volume_json["totalUSDT"].to_f
	end

	def XMR
		return @volume_json["totalXMR"].to_f
	end

	def XUSD
		return @volume_json["totalXUSD"].to_f
	end
end