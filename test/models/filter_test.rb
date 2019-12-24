# frozen_string_literal: true

require 'test_helper'

class FilterTest < ActiveSupport::TestCase
  setup do
    @filter = build(:filter, name: 'test')
  end

  test 'should be valid' do
    assert @filter.valid?
  end

  test '#on_lost_user should decrement user count' do
    assert_difference('@filter.user_count', -1) do
      @filter.save!
      @filter.on_lost_user
      @filter.reload
    end
  end

  test '#on_gained_user should increment user count' do
    assert_difference('@filter.user_count') do
      @filter.save!
      @filter.on_gained_user
      @filter.reload
    end
  end

  test '#spoilered_tag_list should return comma-delimited tag names' do
    @tag1 = create(:safe)
    @tag2 = create(:suggestive)
    @filter.spoilered_tags = [@tag1, @tag2]
    assert_equal [@tag1.name, @tag2.name].join(', '), @filter.spoilered_tag_list
  end

  test '#spoilered_tag_list= should work' do
    @tag1 = create(:safe)
    @tag2 = create(:suggestive)
    @filter.spoilered_tag_list = @tag1.name
    assert @filter.spoilered_tags - [@tag1] == []

    @filter.spoilered_tag_list = [@tag1.name, @tag2.name].join(', ')
    assert @filter.spoilered_tags - [@tag1, @tag2] == [] # not testing order

    @filter.spoilered_tag_list = ''
    assert_empty @filter.spoilered_tags.to_a
  end

  test '#hidden_tag_list should return comma-delimited tag names' do
    @tag1 = create(:safe)
    @tag2 = create(:suggestive)
    @filter.hidden_tags = [@tag1, @tag2]
    assert_equal [@tag1.name, @tag2.name].join(', '), @filter.hidden_tag_list
  end

  test '#hidden_tag_list= should work' do
    @tag1 = create(:safe)
    @tag2 = create(:suggestive)
    @filter.hidden_tag_list = @tag1.name
    assert @filter.hidden_tags - [@tag1] == []

    @filter.hidden_tag_list = [@tag1.name, @tag2.name].join(', ')
    assert @filter.hidden_tags - [@tag1, @tag2] == [] # not testing order

    @filter.hidden_tag_list = ''
    assert_empty @filter.hidden_tags.to_a
  end

  test 'indexing should work' do
    assert_not_nil @filter.as_indexed_json
    # nothing to test
  end
end
