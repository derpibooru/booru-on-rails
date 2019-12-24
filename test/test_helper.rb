# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'
require 'vcr'
require 'webmock/minitest'

ActiveRecord::Base.logger.level = 0

WebMock.disable_net_connect!(allow_localhost: true)
VCR.configure do |c|
  c.ignore_localhost = true
  c.ignore_hosts 'elasticsearch'
  c.cassette_library_dir = "#{::Rails.root}/test/fixtures/cassettes"
  c.hook_into :webmock # or :fakeweb
end

class ActiveSupport::TestCase
  # Add more helper methods to be used by all tests here...
  include FactoryBot::Syntax::Methods
  fixtures :filters

  def self.prepare
    [Image, Tag, Comment, Gallery, Filter, Post, Report].each do |m|
      m.index_name "test_#{m.model_name.plural}"
      m.__elasticsearch__.tap do |es|
        es.create_index!(force: true)
        es.import
        es.refresh_index!
      end
    end
    $flipper[:webm_generation].enable
    $flipper[:livestream_updates].enable
    $flipper[:april_fools].disable
    $flipper[:image_uploads].enable
    $flipper[:image_optimisation].enable
    $flipper[:site_interactivity].enable
    $flipper[:captcha].disable
    $flipper[:new_account_lock].disable
  end

  def refresh_index(model)
    model.__elasticsearch__.refresh_index!
  end

  def setup_test_users
    @user = create(:user)
    @dupe_assistant = create(:dupe_assistant)
    @image_assistant = create(:image_assistant)
    @comment_assistant = create(:comment_assistant)
    @tag_assistant = create(:tag_assistant)
    @admin = create(:admin)
    @moderator = create(:moderator)
  end
end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end

ActiveSupport::TestCase.prepare
