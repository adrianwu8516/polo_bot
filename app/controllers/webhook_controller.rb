class WebhookController < ApplicationController
  
  protect_from_forgery :except => [:callback]

require 'line/bot'
require 'net/http'

def client
  client = Line::Bot::Client.new { |config|
  config.channel_secret = 'd60c7f003ea03b1737ef3ceff75e5fbb'
  config.channel_token = 'OyxxG4A0gRn9Y+XjSeiZBsRjXrkvguTnqSpfam2WemnFu44yanS1KaWdM6M9k3GvRku4a8kvG4ZqaoWU7JvifeciOPoEcWCKc6vBrbV5eG7cC2XaxhHtt56DmFmeTzJtV4392pD9P+RFFEaIexaIyAdB04t89/1O/w1cDnyilFU='
  }
end



def callback

  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']

  event = params["events"][0]
  event_type = event["type"]

  #送られたテキストメッセージをinput_textに取得
  input_text = event["message"]["text"]

  events = client.parse_events_from(body)

  events.each { |event|

    case event
      when Line::Bot::Event::Message
        case event.type
          #テキストメッセージが送られた場合、そのままおうむ返しする
          when Line::Bot::Event::MessageType::Text
             message = {
                  {type: 'text',text: "復唱するよ。"},
                  {type: 'text',text: input_text}
              }

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

end  #def


end