# encoding: utf-8
require 'polo_API_package'
require 'line_client'
require 'line/bot'
require 'net/http'
require 'reminder_library'

def client
    client = Line::Bot::Client.new { |config|
      config.channel_secret = Rails.configuration.line_credential['channel_secret']
      config.channel_token = Rails.configuration.line_credential['channel_token']
    }
end

namespace :regular do
    desc "每5分鐘對於個股變動進行追蹤"
    task :drastic_price_change => :environment do
        user_id = "Ua9486d09308c36ca4e7fd93614723d1f"
        drastic_price_change_reminder("USDT", "BTC", user_id)
    end
end