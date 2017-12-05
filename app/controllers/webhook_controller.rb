class WebhookController < ApplicationController

  protect_from_forgery :except => [:callback]

  require 'line/bot'
  require 'net/http'
  require 'polo_API_package'
  require 'reminder_library'

  def client
    client = Line::Bot::Client.new { |config|
      config.channel_secret = Rails.configuration.line_credential['channel_secret']
      config.channel_token = Rails.configuration.line_credential['channel_token']
    }
  end

  def callback

    signature = request.env['HTTP_X_LINE_SIGNATURE']

    event = params["events"][0]
    user_id = event["source"]["userId"]

    body = request.body.read
    events = client.parse_events_from(body)
    events.each { |event|
      puts "\n\n\n"
      puts event
      puts "\n\n\n"
      case event
        when Line::Bot::API::Error
          puts "\n\n\n"
          puts event["message"]
          puts event["details"]
          puts "\n\n\n"
        when Line::Bot::Event::Postback
          postback_data = event["postback"]["data"]
          message = postbackHandler(postback_data)

        when Line::Bot::Event::Message
          #送られたテキストメッセージをinput_textに取得
          input_text = event["message"]["text"].upcase
          case event.type
            when Line::Bot::Event::MessageType::Text
              message = messageTextHandler(input_text, user_id)
            else
              message = order_fail_message
          end

        when Line::Bot::Event::Follow
          message = followHanlder(user_id)

        when Line::Bot::Event::Unfollow
          unfollowHanlder(user_id)
      end

      unless event['replyToken'].nil?
        client.reply_message(event['replyToken'],message)
      end
    } #events.each
  end

# Menu/Message templates

  def hello_meun
    message ={
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
        "type": "buttons",
        "thumbnailImageUrl": "https://i.imgur.com/QnUv4ER.jpg",
        "title": "歡迎加入Crypto Assistant",
        "text": "我們的宗旨是，不浪費時間天天掛在網路上研究最新行情，照樣也能爽賺一波！！",
        "actions": [
          {"type": "message", "label": "直接開始", "text": "MENU"},
          {"type": "message", "label": "使用說明", "text": "GUIDE"}
        ]
      }
    }
  end

  def main_meun
    message ={
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
        "type": "buttons",
        "title": "錢錢錢，哪裡有錢！",
        "text": "我的口袋聞到了錢的味道",
        "actions": [
          {"type": "postback", "label": "報價","data": "Need_Quote"},
          {"type": "postback", "label": "訂閱提醒", "data": "Need_Reminder"},
          {"type": "message", "label": "今日早報", "text": "NEWS"},
          {"type": "uri", "label": "See the project!", "uri": "https://github.com/kkmanwilliam/polo_bot"}
        ]
      }
    }
  end

  def need_quote_menu
    message ={
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
        "type": "buttons",
        "title": "以Poloniex，對USDT數據為準",
        "text": "輸入例如xmr_btc可查詢其他市場，munu返回主選單。",
        "actions": [
          {"type": "message", "label": "BTC", "text": "USDT_BTC"},
          {"type": "message", "label": "ETH", "text": "USDT_ETH"},
          {"type": "message", "label": "XMR", "text": "USDT_XMR"},
          {"type": "message", "label": "ZEC", "text": "USDT_ZEC"}
        ]
      }
    }
  end

  def need_reminder_menu
    message ={
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
        "type": "buttons",
        "title": "目前提供訂閱，每日行情晨報，各檔價量即時監控報告。",
        "text": "「早報」提供每日市場焦點訊息，主要貨幣市況等。「各檔訂閱」包含即時暴漲暴跌監控，巨量成交監控。",
        "actions": [
          {"type": "message", "label": "目前訂閱", "text": "SUBSCRIPTION"},
          {"type": "message", "label": "使用說明", "text": "GUIDE"}
        ]
      }
    }
  end

  def guide_message
    message = [
        {type: 'text', text: "用法說明：\n輸入BTC_ETH_on可以開啟訂閱BTC對ETH的即時訊息。\n輸入BTC_ETH_off則可以關閉監控。\nUSDT_ETH_on則是開啟監控USDT對ETH的監控，以此類推。"},
        {type: 'text', text: "輸入貨幣名稱可以看到目前可以訂閱的交易市場。例如ZEC可以回傳目前有開放的ZEC市場。"}
      ]
  end

  def specific_currency_check_message(input_text)
    if getCurrencies.include? input_text
      tradingCurrencies_str = "\n目前開放交易市場：\n"+getTradingCurrencies_single(input_text).join("\n")
    else
      tradingCurrencies_str = "\nPoloniex未開放交易"
    end
    info = Coinmarketcap.where(symbol: input_text).first
    reply_info = info.currency_name + "(" + info.symbol + ")\n" + "Ranking:" + info.ranking.to_s + tradingCurrencies_str
    message = [{type: 'text', text: reply_info}]
  end

  def poloniex_now(input_text)
    input_text = pairCorrector(input_text)
    t = getTickerPair(input_text)
    message = [
      {type: 'text', text: getReadablePair(input_text) + ' Price : ' + t.last.to_s},
      {type: 'text', text: 'Change(24h) : ' + t.percentChangeString}
    ]
  end
  def order_fail_message
    message = [{type: 'text', text: "這並不是一個指令或貨幣名稱，請輸入help取得更多說明！"}]
  end

  def no_market_message
    message = [{type: 'text', text: "Poloniex中沒有這種交易！"}]
  end

  def setting_fail_message
    message = [{type: 'text', text: "設置失敗，請檢查輸入\n新增追蹤：+ETH_BTC>30\n取消追蹤：-ETH_BTC>30"}]
  end

  def fix_price_setting(input_text, user_id)
    setting_info = input_text[1..-1].split(/(<|>)/)
    setting_info[0] = pairCorrector(setting_info[0])
    if (getTradingCurrencies.include? setting_info[0])
      target = FixPrice.where(currency_pair: setting_info[0],lineuser_id: user_id,logic: setting_info[1],setting_price:setting_info[2], status: "ON").last
      if input_text.include? "+"
        if target.nil?
          FixPrice.create(currency_pair: setting_info[0],lineuser_id: user_id,logic: setting_info[1],setting_price:setting_info[2], status: "ON")
          message = [{type: 'text', text: "Price Reminder On\n"+setting_info[0]+setting_info[1]+setting_info[2]}]
        else
          message = record_refuse_message("exist")
        end
      elsif input_text.include? "-"
        if target.update(status: "OFF")
          message = [{type: 'text', text: "Price Reminder Off\n"+setting_info[0]+setting_info[1]+setting_info[2]}]
        else
          message = record_refuse_message("nonexist")
        end
      else
        message = setting_fail_message
      end
    else
      message = no_market_message
    end
    return message
  end

  def subscription_setting(input_text, user_id)
    setting_info = pairCorrector(input_text[1..-1])
    if (getTradingCurrencies.include? setting_info)
      target = Subscription.where(currency_pair: setting_info, lineuser_id: user_id, status: "ON")
      if input_text.include? "+"
        if target.nil?
          Subscription.create(currency_pair: setting_info, lineuser_id: user_id, status: "ON")
          message = [{type: 'text', text: "Subscription On:\n"+setting_info}]
        else
          message = record_refuse_message("exist")
        end
      elsif input_text.include? "-"
        if target.update(status: "OFF")
          message = [{type: 'text', text: "Subscription Off:\n"+setting_info}]
        else
          message = record_refuse_message("nonexist")
        end
      else
        message = setting_fail_message
      end
    else
      message = no_market_message
    end
    return message
  end

  def record_refuse_message(status_str)
    status_str == "exist" ? reply_str = "這個項目已經設定過了" : reply_str = "沒有這個項目可供刪除"
    message ={
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
        "type": "buttons",
        "text": reply_str+"，請參閱",
        "actions": [
          {"type": "message", "label": "目前訂閱", "text": "SUBSCRIPTION"},
          {"type": "message", "label": "使用說明", "text": "GUIDE"}
        ]
      }
    }
  end

  def marketcap10_message
    sqlite_sql = '
    select
        ranking,
        symbol as symbol,
        currency_name as currency_name,
        market_cap/10000000000 as market_cap,
        market_cap / (select sum(market_cap) from coinmarketcaps) * 100 as percent
    from coinmarketcaps
    where date(created_at) = date ("now") and ranking < 16
    order by ranking'
    string_line = ""
    records_array = ActiveRecord::Base.connection.execute(sqlite_sql)
    records_array[0..14].each do |hash|
      string_line = string_line + hash["ranking"].to_s + "."+hash["currency_name"]+"/"+hash["symbol"]+" : "+hash["market_cap"].to_s[0..5]+"B("+hash["percent"].to_s[0..4]+"%)\n\n"
    end
    message = [{type: 'text', text:"本日市場規模前15名"},
               {type: 'text', text:string_line[0..-5]}]# Not yet, should put into database
  end

  def pricechange10_message # Not yet
    sqlite_sql_up = '
    select
        ranking,
        currency_name,
        symbol as symbol,
        daily_change
    from coinmarketcaps
    where date(created_at) = date ("now") and ranking < 51 and daily_change > 0
    order by daily_change desc limit 5
    '
    sqlite_sql_down = '
    select
        ranking,
        currency_name,
        symbol as symbol,
        daily_change
    from coinmarketcaps
    where date(created_at) = date ("now") and ranking < 51 and daily_change < 0
    order by daily_change limit 5
    '
    string_line = ""
    records_array_up = ActiveRecord::Base.connection.execute(sqlite_sql_up)
    records_array_down = ActiveRecord::Base.connection.execute(sqlite_sql_down)
    records_array_up.each do |hash|
      string_line = string_line + hash["currency_name"]+"/"+hash["symbol"]+"(rank"+hash["ranking"].to_s+"): price"+(hash["daily_change"]>0 ? " up " : " down ")+hash["daily_change"].to_s+"%\n\n"
    end
    records_array_down.each do |hash|
      string_line = string_line + hash["currency_name"]+"/"+hash["symbol"]+"(rank"+hash["ranking"].to_s+"): price"+(hash["daily_change"]>0 ? " up " : " down ")+hash["daily_change"].to_s+"%\n\n"
    end
    message = [{type: 'text', text:"本日漲跌幅15名"},
               {type: 'text', text:string_line[0..-5]}]# Not yet, should put into database
  end

  def capchange5_message
    sqlite_sql = "
    select  d1.symbol as symbol,
            d1.currency_name as currency_name,
            (d1.market_cap - market_cap2) /market_cap2 * 100 as market_cap_change,
            d1.weekly_change as weekly_change,
            d1.ranking as ranking
      from coinmarketcaps as d1 INNER JOIN (
        select ranking as ranking2,
              market_cap as market_cap2,
              symbol,
              currency_name
        from coinmarketcaps
        where date(created_at) = date ('now' , '-1 day')
        ) as d2 on d1.symbol = d2.symbol and d1.currency_name = d2.currency_name
      where date(created_at) = date ('now') and d1.ranking < 101
      order by market_cap_change desc limit 5"
    string_line = ""
    records_array = ActiveRecord::Base.connection.execute(sqlite_sql)
    records_array.each do |hash|
      string_line = string_line + hash["currency_name"]+"/"+hash["symbol"]+" : market cap up "+hash["market_cap_change"].to_s[0..5]+"%, weekly price " + (hash["weekly_change"]>0 ? "up " : "down ")+hash["weekly_change"].to_s+"% and now ranked "+hash["ranking"].to_s+"\n\n"
    end
    message = [{type: 'text', text:"本日市值上漲前5名"},
               {type: 'text', text:string_line[0..-5]}]
  end

  def top15change_message 
    string_line = ""
    sqlite_sql = '
    select   
          d1.ranking as ranking,
          d1.symbol as symbol,
          d1.daily_change as price_change,
          d1.currency_name as currency_name,
          ranking2 - d1.ranking as ranking_change
    from coinmarketcaps as d1 INNER JOIN (
      select ranking as ranking2,
            market_cap as market_cap2,
            symbol,
            currency_name
      from coinmarketcaps
      where date(created_at) = date ("now" , "-1 day")
      ) as d2 on d1.symbol = d2.symbol and d1.currency_name = d2.currency_name
    where date(created_at) = date ("now") and d1.ranking < 16 and (ranking2 != d1.ranking)
    order by ranking_change desc'
    records_array = ActiveRecord::Base.connection.execute(sqlite_sql)
    records_array.each do |hash|
      string_line = string_line + "Ranking of "+hash["currency_name"]+"/"+hash["symbol"]+" goes "+(hash["ranking_change"]>0 ? "up " : "down ")+hash["ranking_change"].to_s+", now top"+hash["ranking"].to_s+", price "+(hash["price_change"]>0 ? "up " : "down ")+hash["price_change"].to_s+"%\n\n"
    end
    message = [{type: 'text', text:"本日市場主要變動"},
               {type: 'text', text:string_line[0..-5]}]
  end

  def my_subscription_message(user_id)
    message_str = "固定價格追蹤：\n"
    FixPrice.where(lineuser_id: user_id).all.each do |f|
      message_str = message_str + f.currency_pair + f.logic + f.setting_price.to_s + "\n"
    end
    message_str = message_str + "市場監控訂閱：\n"
    Subscription.where(lineuser_id: user_id).all.each do |s|
      message_str = message_str + s.currency_pair + "\n"
    end
    message = [{type: 'text', text: message_str[0..-2]}]
  end

# Event Handling Logic

  def postbackHandler(postback_data)
    case postback_data
      when "Need_Quote"
        message = need_quote_menu
      when "Need_Reminder"
        message = need_reminder_menu
      when "new_a_setting"
        message = new_a_setting_menu
      when "change_settings"
        message = change_settings_menu
      when "reset_price"
        message = [{type: 'text', text: "Not Implemented"}]
      when "keyin"
        message = [{type: 'text', text: "Type name here!"}]
      when "marketcap10"
        message = marketcap10_message
      when "top15change"
        message = top15change_message
      when "pricechange10"
        message = pricechange10_message
      when "capchange5"
        message = capchange5_message
      when "back"
        message = main_meun
      when "bye"
        message = [{type: 'text', text: "Good Luck Dawg!"}]
      else
        message = [
          {type: 'text', text: "Data received, but I don't understand"},
          {type: 'text', text: "Detailed info : " + postback_data}
        ]
    end
    return message
  end

  def messageTextHandler(input_text, user_id)
    if(getTradingCurrencies.include? pairCorrector(input_text))
      message = poloniex_now(input_text)
    elsif (Coinmarketcap.distinct.pluck(:symbol).include? input_text)
      message = specific_currency_check_message(input_text)
    elsif input_text == 'TEST'
      puts "\nTest Start\n"
      message = morning_news("Ua9486d09308c36ca4e7fd93614723d1f")
      puts "\nTest End\n"
    elsif !input_text[/(\+{1}|\-{1})/].nil? and !input_text[/(<{1}|>{1})/].nil?
      message = fix_price_setting(input_text, user_id)
    elsif !input_text[/(\+{1}|\-{1})/].nil? and input_text[/(<{1}|>{1})/].nil?
      message = subscription_setting(input_text, user_id)
    elsif ['M', 'H', 'MENU', 'HOME'].include? input_text
      message = main_meun
    elsif ['G', 'GUIDE', 'HELP'].include? input_text
      message = guide_message
    elsif ["C", "CURRENCY", "CURRENCIES"].include? input_text
      message = [{type: 'text', text: getCurrencies.sort.join("\n")}]
    elsif ['N', 'T', 'TODAY', 'NEWS'].include? input_text
      message = morning_news
    elsif ["S", "SUB", "SUBSCRIPTION", "SUBSCRIBE"].include? input_text
      message = my_subscription_message(user_id)
    else
      message = order_fail_message
    end
    return message
  end

  def followHanlder(user_id)
    if Lineuser.where(userId: user_id).where(following: true).exists?
      return [{type: 'text', text: "已經註冊過囉！"}]
    else
      @lineuser = Lineuser.new(userId: user_id, following: true, news: false, subscribe: "")
      if @lineuser.save
        return hello_meun
      else
        return [{type: 'text', text: "無法登錄您的帳號"}]
      end
    end
  end

  def unfollowHanlder(user_id)
    if Lineuser.where(userId: user_id).where(following: true).exists?
      records = Lineuser.where(userId: user_id).where(following: true)
      records.each do |record|
        record.update(following: false)
      end
    end
  end

  def morning_news
    news_today = "功能未完成！"
    message = {
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
          "type": "buttons",
          "thumbnailImageUrl": "https://i.imgur.com/USTP1tW.png",
          "imageAspectRatio": "rectangle",
          "imageSize": "cover",
          "title": "Breaking News!!",
          "text": news_today,
          "actions": [
              {"type": "postback", "label": "目前市值Top15", "data": "marketcap10"},
              {"type": "postback", "label": "最大漲幅", "data": "pricechange10"},
              {"type": "postback", "label": "最佳5檔", "data": "capchange5"},
              {"type": "postback", "label": "主要貨幣動向", "data": "top15change"}
          ]
      }
    }
    #client.push_message(lineuser_id, message)
  end
end