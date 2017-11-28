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
          user_id = event["source"]["userId"]
          postback_data = event["postback"]["data"]
          message = [
            {type: 'text', text: "Data Received"},
            {type: 'text', text: postback_data}
          ]
          print '##################################'
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
                  {type: 'text', text: input_text},
                  {type: 'text', text: t.last.to_s}
                ]
              else
                meun(user_id)
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


  def meun(user_id)
    #USAGE : push_exp(user_id)

    message ={
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
          "type": "buttons",
          "thumbnailImageUrl": "https://i.imgur.com/QnUv4ER.jpg",
          "title": "錢錢錢，哪裡有錢！",
          "text": "我的口袋聞到了錢的味道",
          "actions": [
              {
                "type": "postback",
                "label": "報價",
                "data": "action=buy&itemid=123"
              },
              {
                "type": "postback",
                "label": "提醒設置",
                "data": "action=add&itemid=123"
              },
              {
                "type": "uri",
                "label": "See the project!",
                "uri": "https://github.com/kkmanwilliam/polo_bot"
              }
          ]
      }
    }
    client.push_message(user_id, message)
  end

end