# frozen_string_literal: true

ENV['REDIS_HOST'] ||= 'localhost'

require 'redis'
$redis = Redis.new(host: ENV['REDIS_HOST'], driver: :hiredis)

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    $redis.disconnect! if forked
  end
end
