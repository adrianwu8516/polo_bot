# AUTO PUSH Reminders implement

#PriceChange.create(currency_pair: "USDT_BTC",lineuser_id: "Ua9486d09308c36ca4e7fd93614723d1f", period_sec: 300, period_num: 2, range: 0.001, status: "ON" )
#PriceChange.create(currency_pair: "USDT_ETH",lineuser_id: "Ua9486d09308c36ca4e7fd93614723d1f", period_sec: 300, period_num: 2, range: 0.001, status: "ON" )
#FixPrice.create(currency_pair: "USDT_BTC",lineuser_id: "Ua9486d09308c36ca4e7fd93614723d1f",logic:"<",setting_price:12000, status: "ON")
#FixPrice.create(currency_pair: "USDT_ETH",lineuser_id: "Ua9486d09308c36ca4e7fd93614723d1f",logic:">",setting_price:200, status: "ON")

  def fix_price_reminder(currency_pair, logic, setting_price, lineuser_id)
    puts "==============fix_price_reminder_start"
    t = getTickerPair(currency_pair)
    message = {
      "type": "template",
      "altText": "this is a confirm template",
      "template": {
          "type": "confirm",
          "text": "Reminder\n"+getReadablePair(currency_pair)+" "+logic+" "+setting_price.to_s+"\nLastet Price : " + t.last.to_s+"\nChange(24h) : "+t.percentChangeString,
          "actions": [
              {"type": "postback", "label": "Reset", "data": "reset_price"},
              {"type": "postback", "label": "Got it!", "data": "bye"}
          ]
      }
    }
    puts logic
    puts t.last
    puts setting_price
    if (logic == ">") && (t.last >= setting_price.to_f)
      puts message
      client.push_message(lineuser_id, message)
    elsif (logic == "<") && (t.last <= setting_price.to_f)
      puts message
      client.push_message(lineuser_id, message)
    end
  end

  def drastic_price_change_reminder(currency_pair, lineuser_id, period_sec=300, period_num=2, range=0.001)
    # ragne cannot be 0, period_sec can only be 300, 900, 1800, 7200, 14400, 86400
    puts "==============drastic_price_change_reminder_start"
    h = getHistoryInfoPair(currency_pair, period_sec, period_num)
    change = (h.weightedAverage[1].to_f - h.weightedAverage[0].to_f) / h.weightedAverage[0].to_f
    if change > range
      message = {
        "type": "template",
        "altText": "this is a confirm template",
        "template": {
            "type": "confirm",
            "text": "Drastic Change\n"+getReadablePair(currency_pair)+" raised "+ (change*100).to_s[0,4]+"% in past 5 mins, now is "+h.weightedAverage[0].to_s[0,4],
            "actions": [
                {"type": "postback", "label": "Reset", "data": "reset_price"},
                {"type": "postback", "label": "Got it!", "data": "bye"}
            ]
        }
      }
      puts message
      client.push_message(lineuser_id, message)
    elsif change < (-1*range)
      message = {
        "type": "template",
        "altText": "this is a confirm template",
        "template": {
            "type": "confirm",
            "text": "Drastic Change\n"+getReadablePair(currency_pair)+" slumped "+ (change*-100).to_s[0,4]+"%  in past 5 mins, now is "+h.weightedAverage[0].to_s[0,4],
            "actions": [
                {"type": "postback", "label": "Reset", "data": "reset_price"},
                {"type": "postback", "label": "Got it!", "data": "bye"}
            ]
        }
      }
      puts message
      client.push_message(lineuser_id, message)
    end
  end
