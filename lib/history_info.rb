class HistoryInfo

	attr_accessor :date,:high,:low,:open,:close,:volume,:quoteVolume,:weightedAverage

	def initialize(history_json)
		@period_day = history_json.length
		@date = Array.new(@period_day)
		@high = Array.new(@period_day)
		@low = Array.new(@period_day)
		@open = Array.new(@period_day)
		@close = Array.new(@period_day)
		@volume = Array.new(@period_day)
		@quoteVolume = Array.new(@period_day)
		@weightedAverage = Array.new(@period_day)

		for i in 0..(@period_day-1)
			@date[i] = history_json[i]['date']
			@high[i] = history_json[i]['high']
			@low[i] = history_json[i]['low']
			@open[i] = history_json[i]['open']
			@close[i] = history_json[i]['close']
			@volume[i] = history_json[i]['volume']
			@quoteVolume[i] = history_json[i]['quoteVolume']
			@weightedAverage[i] = history_json[i]['weightedAverage']
		end
	end
end