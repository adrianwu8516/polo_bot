# encoding: utf-8
require 'line_client'
require 'line/bot'
require 'net/http'
require 'history_info'
require 'ticker_info'
require 'market_volume'
require 'polo_API_package'
require 'reminder_library'


def client
    client = Line::Bot::Client.new { |config|
      config.channel_secret = Rails.configuration.line_credential['channel_secret']
      config.channel_token = Rails.configuration.line_credential['channel_token']
    }
end

# 無法讓變數跟字符一起跑
# Not open to regular users
def run_price_change_reminder
    puts "========================\nrun_price_change_reminder\n" + Time.current.to_s
    PriceChange.where(status:"ON").each do |task|
    	drastic_price_change_reminder(
	        task.currency_pair,
	        task.lineuser_id,
	        period_sec = task.period_sec,
	        period_num = task.period_num,
	        range =  task.range
        )
    end
end


namespace :regular do
    desc "每5分鐘對於個股變動進行追蹤"
    task :price_change => :environment do
    	run_fix_price_reminder
    	run_drastic_price_change_detector
    	run_drastic_price_change_reminder
        #run_price_change_reminder
    end
end