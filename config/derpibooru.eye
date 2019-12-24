Eye.config do
  logger '/home/derpibooru/derpibooru/log/eye.log'
end
resque_highprio_count = 6
resque_lowprio_count = 3
resque_imageproc_count = 3
resque_videoproc_count = 3
resque_rebuild_count = 1

Eye.application 'derpibooru' do
  working_dir '/home/derpibooru/derpibooru'
  stdall '/home/derpibooru/derpibooru/log/background.log'
  trigger :flapping, times: 10, within: 1.minute, retry_in: 10.minutes
  # check :cpu, every: 10.seconds, below: 100, times: 3
  env 'RAILS_ENV' => ENV['RAILS_ENV'] || 'production'
  stop_on_delete true
  start_grace 10.seconds

  # group 'resque' do
  #   chain grace: 2.seconds
  #   (1..resque_highprio_count).each do |i|
  #     process "resque-highprio-#{i}" do
  #       pid_file "tmp/pids/resque-highprio-#{i}.pid"
  #       daemonize true
  #       start_command 'bundle exec sidekiq -c 1 -q critical -q high -q medium -q mailers'
  #       stop_signals [:QUIT, 30.seconds, :TERM, 10.seconds, :KILL]
  #       stdall "log/resque-highprio-#{i}.log"
  #       # ensure the memory is below 300Mb the last 3 times checked
  #       check :memory, every: 20.seconds, below: 350.megabytes, times: 3
  #     end
  #   end
  #   (1..resque_lowprio_count).each do |i|
  #     process "resque-lowprio-#{i}" do
  #       pid_file "tmp/pids/resque-lowprio-#{i}.pid"
  #       daemonize true
  #       start_command 'bundle exec sidekiq -c 1 -q low -q livestream_updates'
  #       stop_signals [:QUIT, 30.seconds, :TERM, 10.seconds, :KILL]
  #       stdall "log/resque-lowprio-#{i}.log"
  #       # ensure the memory is below 300Mb the last 3 times checked
  #       check :memory, every: 20.seconds, below: 350.megabytes, times: 3
  #     end
  #   end
  #   (1..resque_rebuild_count).each do |i|
  #     process "resque-rebuild-#{i}" do
  #       pid_file "tmp/pids/resque-rebuild-#{i}.pid"
  #       daemonize true
  #       start_command 'bundle exec sidekiq -c 1 -q rebuilds'
  #       stop_signals [:QUIT, 30.seconds, :TERM, 10.seconds, :KILL]
  #       stdall "log/resque-rebuild-#{i}.log"
  #       # ensure the memory is below 300Mb the last 3 times checked
  #       check :memory, every: 20.seconds, below: 350.megabytes, times: 3
  #     end
  #   end
  #   (1..resque_imageproc_count).each do |i|
  #     process "resque-imageproc-#{i}" do
  #       pid_file "tmp/pids/resque-imageproc-#{i}.pid"
  #       daemonize true
  #       start_command 'bundle exec sidekiq -c 1 -q image_processing'
  #       stop_signals [:QUIT, 30.seconds, :TERM, 10.seconds, :KILL]
  #       stdall "log/resque-imageproc-#{i}.log"
  #       # ensure the memory is below 300Mb the last 3 times checked
  #       # check :memory, every: 20.seconds, below: 350.megabytes, times: 3
  #     end
  #   end
  #   (1..resque_videoproc_count).each do |i|
  #     process "resque-videoproc-#{i}" do
  #       pid_file "tmp/pids/resque-videoproc-#{i}.pid"
  #       daemonize true
  #       start_command 'bundle exec sidekiq -c 1 -q video_processing'
  #       stop_signals [:QUIT, 30.seconds, :TERM, 10.seconds, :KILL]
  #       stdall "log/resque-videoproc-#{i}.log"
  #       # ensure the memory is below 300Mb the last 3 times checked
  #       # check :memory, every: 20.seconds, below: 350.megabytes, times: 3
  #     end
  #   end
  # end
  # group 'updaters' do
  #   chain grace: 2.seconds
  #   process 'channel-updater' do
  #     pid_file 'tmp/pids/channel-updater.pid'
  #     daemonize true
  #     start_command 'bundle exec rake booru:channels:updater'
  #     stop_signals [:INT, 30.seconds, :TERM, 10.seconds, :KILL]
  #     stdall 'log/channel-updater.log'
  #     check :memory, every: 20.seconds, below: 350.megabytes, times: 3
  #   end
  # end
end
