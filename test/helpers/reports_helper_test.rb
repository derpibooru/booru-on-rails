# frozen_string_literal: true

require 'test_helper'

class ReportsHelperTest < ActionView::TestCase
  include ReportsHelper

  test 'report is of an image' do
    ActionView::Base.class_eval do # absolutely disgusting
      def scope_key
        {}
      end
    end
    @report = create(:report_of_image)
    assert_match /#{@report.reportable.id}/, link_to_reported_thing(@report.reportable)
  end

  test 'report is of a user' do
    @report = create(:report_of_user)
    assert_match @report.reportable.name, link_to_reported_thing(@report.reportable)
    assert_match /profiles\/#{Regexp.escape(@report.reportable.slug)}/, link_to_reported_thing(@report.reportable)
  end

  test 'report is of a post' do
    @report = create(:report_of_post)
    assert_match /#{@report.reportable.id}/, link_to_reported_thing(@report.reportable)
    assert_match @report.reportable.topic.slug, link_to_reported_thing(@report.reportable)
    assert_match @report.reportable.topic.forum.short_name, link_to_reported_thing(@report.reportable)
  end

  test 'report is of a comment' do
    ActionView::Base.class_eval do # absolutely disgusting
      def scope_key
        {}
      end
    end
    @report = create(:report_of_comment)
    assert_match /#{@report.reportable.id}/, link_to_reported_thing(@report.reportable)
    assert_match @report.reportable.author, link_to_reported_thing(@report.reportable)
    assert_match /#{@report.reportable.image.id}/, link_to_reported_thing(@report.reportable)
  end
end
