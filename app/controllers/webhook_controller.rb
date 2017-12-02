class WebhookController < ApplicationController

  protect_from_forgery :except => [:callback]

  require 'line/bot'
  require 'net/http'

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
      case event
        when Line::Bot::Event::Postback
          postback_data = event["postback"]["data"]
          message = postbackHandler(postback_data)

        when Line::Bot::Event::Message
          #送られたテキストメッセージをinput_textに取得
          input_text = event["message"]["text"].upcase
          case event.type
            when Line::Bot::Event::MessageType::Text
              message = messageTextHandler(input_text)
            else
              message = [{type: 'text', text: "這並不是一個指令或貨幣名稱，請輸入help取得更多說明！"}]
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

# Menu templates

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
    return message
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
          {"type": "uri", "label": "See the project!", "uri": "https://github.com/kkmanwilliam/polo_bot"}
        ]
      }
    }
    return message
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
    return message
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
          {"type": "postback", "label": "目前我的訂閱內容", "data": "my_subscription"},
          {"type": "postback", "label": "訂閱內容總覽", "data": "change_subscription"},
          {"type": "message", "label": "使用說明", "text": "GUIDE"},
        ]
      }
    }
  end

# AUTO PUSH Reminders implement

  def fix_price_reminder(currency_pair, logic, setting_price, user_id)
    t = getTickerPair(currency_pair)

    message = {
      "type": "template",
      "altText": "this is a confirm template",
      "template": {
          "type": "confirm",
          "text": "Reminder\n"+currency_pair+' '+logic+' '+setting_price.to_s+"\nLastet Price : " + t.last.to_s+"\nChange(24h) : "+t.percentChangeString,
          "actions": [
              {"type": "postback", "label": "Reset", "data": "reset_price"},
              {"type": "postback", "label": "Got it!", "data": "bye"}
          ]
      }
    }
    if (logic == '>') && (t.last >= setting_price.to_f)
      client.push_message(user_id, message)
    elsif (logic == '<') && (t.last <= setting_price.to_f)
      client.push_message(user_id, message)
    end
  end

  def drastic_price_change_reminder(currency_A, currency_B, user_id, period_sec=300, period_num=2)
    h = getHistoryInfoPair(currency_A, currency_B, period_sec, period_num)
    change = (h.weightedAverage[1] - h.weightedAverage[0])/h.weightedAverage[0]
    if change > 0
      message = {
        "type": "template",
        "altText": "this is a confirm template",
        "template": {
            "type": "confirm",
            "text": "Drastic Change\n"+currency_B+' to '+currency_A+' raised '+ (change*100).to_s[0,4]+"%" + ' in past 5 mins, now is '+h.weightedAverage[0].to_s[0,4],
            "actions": [
                {"type": "postback", "label": "Reset", "data": "reset_price"},
                {"type": "postback", "label": "Got it!", "data": "bye"}
            ]
        }
      }
      client.push_message(user_id, message)
    elsif change < 0
      message = {
        "type": "template",
        "altText": "this is a confirm template",
        "template": {
            "type": "confirm",
            "text": "Drastic Change\n"+currency_B+' to '+currency_A+' slumped '+ (change*-100).to_s[0,4]+"%" + ' in past 5 mins'+h.weightedAverage[0].to_s[0,4],
            "actions": [
                {"type": "postback", "label": "Reset", "data": "reset_price"},
                {"type": "postback", "label": "Got it!", "data": "bye"}
            ]
        }
      }
      client.push_message(user_id, message)
    end
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
      when "back"
        main_meun(user_id)
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

  def messageTextHandler(input_text)
    input_text = pairGenerator(input_text)
    if(getTradingCurrencies.include? input_text)
      t = getTickerPair(input_text)
      currency_A = input_text.split('_')[0]
      currency_B = input_text.split('_')[1]
      message = [
        {type: 'text', text: currency_B + ' to ' + currency_A + ' Price : ' + t.last.to_s},
        {type: 'text', text: 'Change(24h) : ' + t.percentChangeString}
      ]
    elsif (getCurrencies.include? input_text)
      tradingCurrencies_str = getTradingCurrencies_single(input_text).join("\n")
      message = [{type: 'text', text: "目前開放交易市場：\n"+tradingCurrencies_str}]
    elsif input_text == 'TEST'
      #fix_price_reminder('USDT', 'BTC', '<', '12000', user_id)
      drastic_price_change_reminder('USDT', 'BTC', user_id)
    elsif ['MENU', 'HOME'].include? input_text
      message = main_meun
    elsif ['GUIDE', 'HELP'].include? input_text
      message = [
        {type: 'text', text: "用法說明：\n輸入BTC_ETH_on可以開啟訂閱BTC對ETH的即時訊息。\n輸入BTC_ETH_off則可以關閉監控。\nUSDT_ETH_on則是開啟監控USDT對ETH的監控，以此類推。"},
        {type: 'text', text: "輸入貨幣名稱可以看到目前可以訂閱的交易市場。例如ZEC可以回傳目前有開放的ZEC市場。"}
      ]
    elsif ["CURRENCY", "CURRENCIES", "C"].include? input_text
      message = [{type: 'text', text: getCurrencies.sort.join("\n")}]
    else
      message = [{type: 'text', text: "這並不是一個指令或貨幣名稱，請輸入help取得更多說明！"}]
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

  #fix_price_reminder('USDT', 'BTC', '<', '12000', "Ua9486d09308c36ca4e7fd93614723d1f")
  #drastic_price_change_reminder('USDT', 'BTC', "Ua9486d09308c36ca4e7fd93614723d1f")
end