# AUTO PUSH Reminders implement

#PriceChange.create(currency_pair: "USDT_BTC",lineuser_id: "Ua9486d09308c36ca4e7fd93614723d1f", period_sec: 300, period_num: 2, range: 0.001, status: "ON" )
#PriceChange.create(currency_pair: "USDT_ETH",lineuser_id: "Ua9486d09308c36ca4e7fd93614723d1f", period_sec: 300, period_num: 2, range: 0.001, status: "ON" )
#FixPrice.create(currency_pair: "USDT_BTC",lineuser_id: "Ua9486d09308c36ca4e7fd93614723d1f",logic:"<",setting_price:12000, status: "ON")
#FixPrice.create(currency_pair: "USDT_ETH",lineuser_id: "Ua9486d09308c36ca4e7fd93614723d1f",logic:">",setting_price:200, status: "ON")

  def fix_price_reminder(currency_pair, logic, setting_price, lineuser_id, f)
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
    if (logic == ">") && (t.last >= setting_price.to_f)
      client.push_message(lineuser_id, message)
      f.update(status: "OFF")
    elsif (logic == "<") && (t.last <= setting_price.to_f)
      client.push_message(lineuser_id, message)
      f.update(status: "OFF")
    end
  end

  def run_fix_price_reminder
    puts "=====================\nrun_fix_price_reminder"
    FixPrice.where(status: "ON").to_a.each do |f|
      fix_price_reminder(f.currency_pair, f.logic, f.setting_price, f.lineuser_id, f)
    end
  end

  #發現資料記入DB
  def drastic_price_change_detector(currency_pair, period_sec=300, period_num=2, range=0.03)
    # ragne cannot be 0, period_sec can only be 300, 900, 1800, 7200, 14400, 86400
    h = getHistoryInfoPair(currency_pair, period_sec, period_num)
    change = (h.weightedAverage[1].to_f - h.weightedAverage[0].to_f) / h.weightedAverage[0].to_f
    if !change.is_a? Float
      return
    end
    if change > range
      text = "Drastic Change\n"+getReadablePair(currency_pair)+" raised "+ (change*100).to_s[0,4]+"% in past 5 mins, now is "+h.weightedAverage[0].to_s[0,4]
      PushRecord.create(content: text, message_type: "drastic", news_date: Time.current.strftime("%d/%m/%Y %H:%M"), target_market: currency_pair, status: "Pending")
    elsif change < (-1*range)
      text = "Drastic Change\n"+getReadablePair(currency_pair)+" slumped "+ (change*-100).to_s[0,4]+"%  in past 5 mins, now is "+h.weightedAverage[0].to_s[0,4]
      PushRecord.create(content: text, message_type: "drastic", news_date: Time.current.strftime("%d/%m/%Y %H:%M"), target_market: currency_pair, status: "Pending")
    end
  end

  #只針對有人關注的貨幣市場寫入監控資料
  def run_drastic_price_change_detector
    puts "=====================\nrun_drastic_price_change_detector"
    Subscription.select(:currency_pair).where(status: "ON").distinct.pluck(:currency_pair).each do |currency_pair|
      drastic_price_change_detector(currency_pair)
    end
  end

  def run_drastic_price_change_reminder
    # ragne cannot be 0, period_sec can only be 300, 900, 1800, 7200, 14400, 86400
    puts "=====================\nrun_drastic_price_change_reminder"
    PushRecord.where(status: "Pending").to_a.each do |pending_push_message|
      message = {
        "type": "template",
        "altText": "this is a confirm template",
        "template": {
            "type": "confirm",
            "text": pending_push_message.content,
            "actions": [
                {"type": "postback", "label": "Reset", "data": "reset_price"},
                {"type": "postback", "label": "Got it!", "data": "bye"}
            ]
        }
      }
      Subscription.select(:lineuser_id).where(status: "ON").where(currency_pair: pending_push_message.target_market).to_a.each do |s|
        client.push_message(s.lineuser_id, message)
      end
      pending_push_message.update(status: "Send")
    end
  end
