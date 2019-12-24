# frozen_string_literal: true

require 'flipper'

# pick an adapter
require 'flipper/adapters/redis'
adapter = Flipper::Adapters::Redis.new(Redis.new(host: ENV['REDIS_HOST'], driver: :hiredis))
Flipper.register(:admins) do |actor|
  actor.respond_to?(:role) && actor.role == 'admin'
end

# get a handy dsl instance
$flipper = Flipper.new(adapter)
