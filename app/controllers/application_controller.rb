class ApplicationController < ActionController::Base

	protect_from_forgery with: :exception

	require 'history_info'
	require 'ticker_info'
	require 'market_volume'
	require 'polo_API_package'
	#require 'reminder_library'
end
