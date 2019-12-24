# frozen_string_literal: true

RestClient.proxy = Booru::CONFIG.settings[:proxy_server]
