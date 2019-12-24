# frozen_string_literal: true

namespace :booru do
  namespace :channels do
    desc 'Constantly update channels'
    task updater: :environment do
      Channel.perform_updates
    end
  end
end
