# encoding: utf-8
require 'polo_API_package'
require 'line_client'
require 'line/bot'
require 'net/http'

def client
    client = Line::Bot::Client.new { |config|
      config.channel_secret = Rails.configuration.line_credential['channel_secret']
      config.channel_token = Rails.configuration.line_credential['channel_token']
    }
end

def drastic_price_change_reminder(currency_pare, user_id, period_sec=300, period_num=2, range=0.001)
    # ragne cannot be 0, period_sec can only be 300, 900, 1800, 7200, 14400, 86400
    h = getHistoryInfoPair(currency_pare, period_sec, period_num)
    currency_pair = currency_pair.split('_')
    change = (h.weightedAverage[1] - h.weightedAverage[0])/h.weightedAverage[0]
    if change > range
      message = {
        "type": "template",
        "altText": "this is a confirm template",
        "template": {
            "type": "confirm",
            "text": "Drastic Change\n"+currency_pair[1]+' to '+currency_pair[0]+' raised '+ (change*100).to_s[0,4]+"%" + ' in past 5 mins, now is '+h.weightedAverage[0].to_s[0,4],
            "actions": [
                {"type": "postback", "label": "Reset", "data": "reset_price"},
                {"type": "postback", "label": "Got it!", "data": "bye"}
            ]
        }
      }
      client.push_message(user_id, message)
    elsif change < (-1*range)
      message = {
        "type": "template",
        "altText": "this is a confirm template",
        "template": {
            "type": "confirm",
            "text": "Drastic Change\n"+currency_pair[1]+' to '+currency_pair[0]+' slumped '+ (change*-100).to_s[0,4]+"%" + ' in past 5 mins'+h.weightedAverage[0].to_s[0,4],
            "actions": [
                {"type": "postback", "label": "Reset", "data": "reset_price"},
                {"type": "postback", "label": "Got it!", "data": "bye"}
            ]
        }
      }
      client.push_message(user_id, message)
    end
  end

namespace :regular do
    desc "每5分鐘對於個股變動進行追蹤"
    task :drastic_price_change => :environment do
        user_id = "Ua9486d09308c36ca4e7fd93614723d1f"
        drastic_price_change_reminder("USDT", "BTC", user_id)
    end
end