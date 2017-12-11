# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever


env :PATH, ENV['PATH'] #要用bundle時必須要加

set :output, 'log/cron.log' #設定log的路徑

every 1.day, :at => '9:00 am' do
    rake "regular:coinmarketcapToday"
end

every 1.day, :at => '9:03 am' do
    rake "regular:daily_news"
end

every 5.minutes do
	rake "regular:price_change"
end