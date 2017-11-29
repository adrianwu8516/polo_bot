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

    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']

    event = params["events"][0]
    event_type = event["type"]
    user_id = event["source"]["userId"]

    events = client.parse_events_from(body)
    events.each { |event|
      case event
        when Line::Bot::Event::Postback
          postback_data = event["postback"]["data"]
          case postback_data
            when "Need_Quote"
              message = need_quote_menu
            when "Need_Reminder"
              puts "Saw Need_Reminder"
              message = need_reminder_menu
              puts message
            when "new_a_setting"
              message = new_a_setting_menu
            when "change_settings"
              message = change_settings_menu
            when "keyin"
              message = [{type: 'text', text: "Type name here!"}]
              client.reply_message(event['replyToken'],message)
            when "back"
              main_meun(user_id)
            else
              message = [
                {type: 'text', text: "Data received, but I don't understand"},
                {type: 'text', text: "Detailed info : " + postback_data}
              ]
          end
          client.reply_message(event['replyToken'],message)
        when Line::Bot::Event::Message
          #送られたテキストメッセージをinput_textに取得
          input_text = event["message"]["text"]

          case event.type
            #テキストメッセージが送られた場合、そのままおうむ返しする
            when Line::Bot::Event::MessageType::Text
              currencies = JSON.parse(Poloniex.get('returnCurrencies')).keys
              if(currencies.include? input_text)
                t = getTicker(input_text)
                message = [
                  {type: 'text', text: input_text + 'Price : ' + t.last.to_s},
                  {type: 'text', text: 'Change(24h) : ' + t.percentChange.to_s}
                ]
              else
                main_meun(user_id)
              end

            #画像が送られた場合、適当な画像を送り返す
            #画像を返すには、画像が保存されたURLを指定する。
            #なお、おうむ返しするには、１度AWSなど外部に保存する必要がある。ここでは割愛する
            when Line::Bot::Event::MessageType::Image
              image_url = "https://XXXXXXXXXX/XXX.jpg"  #httpsであること
              message = {
                type: "image",
                originalContentUrl: image_url,
                previewImageUrl: image_url
              }
          end #event.type
          #メッセージを返す
          client.reply_message(event['replyToken'],message)
      end #event
    } #events.each
  end


  def main_meun(user_id)
    # 不應該用push來做
    message ={
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
        "type": "buttons",
        "thumbnailImageUrl": "https://i.imgur.com/QnUv4ER.jpg",
        "title": "錢錢錢，哪裡有錢！",
        "text": "我的口袋聞到了錢的味道",
        "actions": [
          {"type": "postback", "label": "報價","data": "Need_Quote"},
          {"type": "postback", "label": "提醒設置", "data": "Need_Reminder"},
          {"type": "uri", "label": "See the project!", "uri": "https://github.com/kkmanwilliam/polo_bot"}
        ]
      }
    }
    client.push_message(user_id, message)
  end

  def need_quote_menu
    message ={
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
        "type": "buttons",
        "title": "以Poloniex，對USDT數據為準",
        "text": "任意輸入可以返回主選單",
        "actions": [
          {"type": "message", "label": "BTC", "text": "BTC"},
          {"type": "message", "label": "ETH", "text": "ETH"},
          {"type": "message", "label": "ZEC", "text": "ZEC"},
          {"type": "postback","label": "自行輸入", "data": "keyin"}
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
        "title": "設置提醒條件，我們會隨時告訴你最新資訊",
        "text": "任意輸入可以返回主選單",
        "actions": [
          {"type": "postback", "label": "設置提醒條件", "data": "new_a_setting"},
          {"type": "postback", "label": "調整目前設置", "data": "change_settings"}
        ]
      }
    }
  end

  def new_a_setting_menu
    message ={
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
          "type": "buttons",
          "title": "設置想要的提醒條件",
          "text": "任意輸入可以返回主選單",
          "actions": [
              {"type": "postback","label": "早晨9點定時提醒", "data": "morning_letter"},
              {"type": "postback","label": "漲跌7％提醒", "data": "activist"}
          ]
      }
    }
    return message
  end

end