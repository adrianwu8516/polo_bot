class TickerInfo

	attr_reader :last, :lowestAsk, :highestBid, :percentChange, :baseVolume, :quoteVolume, :isFrozen, :high24hr, :low24hr, :percentChangeString

	def initialize(ticker_json)
		@last = ticker_json["last"].to_f
		@lowestAsk = ticker_json["lowestAsk"].to_f
		@highestBid = ticker_json["highestBid"].to_f
		@percentChange = ticker_json["percentChange"].to_f
		@baseVolume = ticker_json["baseVolume"].to_f
		@quoteVolume = ticker_json["quoteVolume"].to_f
		@isFrozen = ticker_json["isFrozen"] == "0" ? false : true
		@high24hr = ticker_json["high24hr"].to_f
		@low24hr = ticker_json["low24hr"].to_f
	end

	def percentChangeString
		return (@percentChange*100).to_s[0,5]+"%"
	end
end