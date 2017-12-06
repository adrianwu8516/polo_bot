def news_message_record(message, type)
  PushRecord.create(content: message, message_type: type, target_market: "All", news_date: Time.current.strftime("%d/%m/%Y"))
end

# queries
def price_up5
  query_sqlite =
  'select
      ranking,
      currency_name,
      symbol as symbol,
      daily_change
  from coinmarketcaps
  where date(created_at) = date ("now") and ranking < 51 and daily_change > 0
  order by daily_change desc limit 5'
end

def price_down5
  query_sqlite =
  'select
      ranking,
      currency_name,
      symbol as symbol,
      daily_change
  from coinmarketcaps
  where date(created_at) = date ("now") and ranking < 51 and daily_change < 0
  order by daily_change limit 5'
end

def market_cap10
  query_sqlite =
  'select
      ranking,
      symbol as symbol,
      currency_name as currency_name,
      market_cap/10000000000 as market_cap,
      market_cap / (select sum(market_cap) from coinmarketcaps) * 100 as percent
  from coinmarketcaps
  where date(created_at) = date ("now") and ranking < 16
  order by ranking'
end

def cap_change5
  query_sqlite =
  "select  d1.symbol as symbol,
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
end

def top15change
  query_sqlite =
  'select
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
end

def marketcap10_message
  string_line = ""
  records_array = ActiveRecord::Base.connection.execute(market_cap10)
  records_array[0..14].each do |hash|
    string_line = string_line + hash["ranking"].to_s + "."+hash["currency_name"]+"/"+hash["symbol"]+" : "+hash["market_cap"].to_s[0..5]+"B("+hash["percent"].to_s[0..4]+"%)\n\n"
  end
  message = string_line[0..-3]
  news_message_record(message, "marketcap10")
end

def pricechange10_message
  string_line = ""
  records_array_up = ActiveRecord::Base.connection.execute(price_up5)
  records_array_down = ActiveRecord::Base.connection.execute(price_down5)
  records_array_up.each do |hash|
    string_line = string_line + hash["currency_name"]+"/"+hash["symbol"]+"(rank"+hash["ranking"].to_s+"): price"+(hash["daily_change"]>0 ? " up " : " down ")+hash["daily_change"].to_s+"%\n\n"
  end
  records_array_down.each do |hash|
    string_line = string_line + hash["currency_name"]+"/"+hash["symbol"]+"(rank"+hash["ranking"].to_s+"): price"+(hash["daily_change"]>0 ? " up " : " down ")+hash["daily_change"].to_s+"%\n\n"
  end
  message = string_line[0..-5]
  news_message_record(message, "pricechange10")
end

def capchange5_message
  string_line = ""
  records_array = ActiveRecord::Base.connection.execute(cap_change5)
  records_array.each do |hash|
    string_line = string_line + hash["currency_name"]+"/"+hash["symbol"]+" : market cap up "+hash["market_cap_change"].to_s[0..5]+"%, weekly price " + (hash["weekly_change"]>0 ? "up " : "down ")+hash["weekly_change"].to_s+"% and now ranked "+hash["ranking"].to_s+"\n\n"
  end
  message = string_line[0..-5]
  news_message_record(message, "capchange5")
end

def top15change_message
  string_line = ""
  records_array = ActiveRecord::Base.connection.execute(top15change)
  records_array.each do |hash|
    string_line = string_line + "Ranking of "+hash["currency_name"]+"/"+hash["symbol"]+" goes "+(hash["ranking_change"]>0 ? "up " : "down ")+hash["ranking_change"].to_s+", now top"+hash["ranking"].to_s+", price "+(hash["price_change"]>0 ? "up " : "down ")+hash["price_change"].to_s+"%\n\n"
  end
  message = string_line[0..-5]
  news_message_record(message, "top15change")
end


namespace :regular do
    desc "每天生產早報，存入DB"
    task :daily_news => :environment do
      marketcap10_message
      pricechange10_message
      capchange5_message
      top15change_message
    end
end