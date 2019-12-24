# frozen_string_literal: true

# See https://bogomips.org/unicorn/Unicorn/Configurator.html for complete
# documentation.

worker_processes 2
working_directory '/home/derpibooru/derpibooru'

listen '/home/derpibooru/derpibooru/tmp/sockets/.unicorn.1.sock', backlog: 64
listen 9292, tcp_nopush: true

timeout 30

pid '/home/derpibooru/derpibooru/tmp/pids/unicorn.pid'
stdout_path '/home/derpibooru/derpibooru/log/unicorn.stdout.log'
stderr_path '/home/derpibooru/derpibooru/log/unicorn.stderr.log'
preload_app true
check_client_connection false

before_fork do |server, worker|
  # there's no need for the master process to hold a connection
  ActiveRecord::Base.connection.disconnect!

  # The following is only recommended for memory/DB-constrained
  # installations.  It is not needed if your system can house
  # twice as many worker_processes as you have configured.
  #
  # This allows a new master process to incrementally
  # phase out the old master process with SIGTTOU to avoid a
  # thundering herd (especially in the "preload_app false" case)
  # when doing a transparent upgrade.  The last worker spawned
  # will then kill off the old master process with a SIGQUIT.
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

  # Throttle the master from forking too quickly (for incremental kill-off only)
  sleep 1
end

after_fork do |_server, _worker|
  require 'flipper/adapters/redis'

  ActiveRecord::Base.establish_connection
  $redis = Redis.new(host: ENV['REDIS_HOST'], driver: :hiredis)
  $flipper = Flipper.new(Flipper::Adapters::Redis.new($redis))
end
