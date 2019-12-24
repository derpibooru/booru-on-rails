# frozen_string_literal: true

require 'test_helper'
require 'search_parser'

class SearchParserTest < ActiveSupport::TestCase
  def tags_parser(expr, options = {})
    SearchParser.new(expr, 'namespaced_tags.name', options)
  end

  test 'returns match_none for an empty search' do
    assert_equal({ match_none: {} },
                 tags_parser('').parsed)
  end

  test 'returns single term for a single search' do
    assert_equal({ term: { 'namespaced_tags.name' => 'pinkie pie' } },
                 tags_parser('pinkie pie').parsed)
  end

  test 'escapes characters with a backslash' do
    assert_equal({ term: { 'namespaced_tags.name' => '"pinkie: the pie" (*cosplayer*)' } },
                 tags_parser('\"pinkie\: the \pie\" \(\*cosplayer\*\)').parsed)
  end

  test 'allows implicit wildcards' do
    parser = tags_parser('*test*')
    assert_equal({ wildcard: { 'namespaced_tags.name' => '*test*' } },
                 parser.parsed)
    assert parser.requires_query
  end

  test 'escapes with surrounding double quotes' do
    parser = tags_parser('"\"pinkie: the pie\" (*cosplayer*)"')
    assert_equal({ term: { 'namespaced_tags.name' => '"pinkie: the pie" (*cosplayer*)' } },
                 parser.parsed)
    assert_not parser.requires_query
  end

  test 'allows double quotes within a term (without escaping)' do
    assert_equal({ wildcard: { 'namespaced_tags.name' => 'element of laughter* "pinkie pie"' } },
                 tags_parser('element of laughter* "pinkie pie"').parsed)
  end

  test 'supports AND operations' do
    assert_equal({ bool: { must: [
                   { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                   { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                 ] } },
                 tags_parser('pinkie pie AND twilight sparkle').parsed)
  end

  test 'supports AND operations with condensed commas' do
    assert_equal({ bool: { must: [
                   { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                   { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                 ] } },
                 tags_parser('pinkie pie,twilight sparkle').parsed)
  end

  test 'supports OR operations' do
    assert_equal({ bool: { should: [
                   { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                   { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                 ] } },
                 tags_parser('pinkie pie || twilight sparkle').parsed)
  end

  test 'supports NOT operations' do
    assert_equal({ bool: { must_not: [
                   { term: { 'namespaced_tags.name' => 'flutterbat' } }
                 ] } },
                 tags_parser('NOT flutterbat').parsed)
  end

  test 'supports stacked NOT operators elegantly' do
    assert_equal({ bool: { must: [
                   { term: { 'namespaced_tags.name' => 'flutterbat' } },
                   { bool: { must_not: [
                     { term: { 'namespaced_tags.name' => 'fluttershy' } }
                   ] } }
                 ] } },
                 tags_parser('!!!!flutterbat,!!!fluttershy').parsed)
  end

  test 'supports NOT operations inside AND expressions' do
    assert_equal({ bool: { must: [
                   { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                   { bool: { must_not: [
                     { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                   ] } }
                 ] } },
                 tags_parser('pinkie pie && !twilight sparkle').parsed)
  end

  test 'supports NOT operations inside OR expressions' do
    assert_equal({ bool: { should: [
                   { bool: { must_not: [
                     { term: { 'namespaced_tags.name' => 'pinkie pie' } }
                   ] } },
                   { bool: { must_not: [
                     { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                   ] } }
                 ] } },
                 tags_parser('NOT pinkie pie || !twilight sparkle').parsed)
  end

  test 'maintains correct order of operations' do
    assert_equal({ bool: { should: [
                   { bool: { must: [
                     { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                     { bool: { must_not: [
                       { term: { 'namespaced_tags.name' => 'fluttershy' } }
                     ] } }
                   ] } },
                   { bool: { must: [
                     { term: { 'namespaced_tags.name' => 'apple bloom' } },
                     { term: { 'namespaced_tags.name' => 'applejack' } }
                   ] } }
                 ] } },
                 tags_parser('pinkie pie && !fluttershy || apple bloom && applejack').parsed)
  end

  test 'flattens a chain of AND operations while preserving order' do
    assert_equal({ bool: { must: [
                   { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                   { bool: { must_not: [
                     { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                   ] } },
                   { bool: { must_not: [
                     { term: { 'namespaced_tags.name' => 'fluttershy' } }
                   ] } },
                   { term: { 'namespaced_tags.name' => 'bats!' } }
                 ] } },
                 tags_parser('pinkie pie && !twilight sparkle,!fluttershy && bats!').parsed)
  end

  test 'flattens a chain of OR operations while preserving order' do
    assert_equal({ bool: { should: [
                   { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                   { bool: { must_not: [
                     { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                   ] } },
                   { bool: { must_not: [
                     { term: { 'namespaced_tags.name' => 'fluttershy' } }
                   ] } },
                   { term: { 'namespaced_tags.name' => 'bats!' } }
                 ] } },
                 tags_parser('pinkie pie || !twilight sparkle OR !fluttershy || bats!').parsed)
  end

  test 'maintains correct order of operations with wildcards' do
    assert_equal({ bool: { should: [
                   { wildcard: { 'namespaced_tags.name' => 'pinkie*' } },
                   { bool: { must: [
                     { bool: { must_not: [
                       { wildcard: { 'namespaced_tags.name' => 'flutter*' } }
                     ] } },
                     { wildcard: { 'namespaced_tags.name' => 'apple*' } }
                   ] } },
                   { term: { 'namespaced_tags.name' => 'applejack' } }
                 ] } },
                 tags_parser('pinkie* || !flutter* && apple* || applejack').parsed)
  end

  test 'handles redundant parentheses elegantly' do
    assert_equal({ bool: { should: [
                   { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                   { bool: { must: [
                     { bool: { must_not: [
                       { term: { 'namespaced_tags.name' => 'fluttershy' } }
                     ] } },
                     { wildcard: { 'namespaced_tags.name' => 'apple*' } }
                   ] } },
                   { term: { 'namespaced_tags.name' => 'applejack' } }
                 ] } },
                 tags_parser('(pinkie pie || (!fluttershy && apple*) || (applejack))').parsed)
  end

  test 'permits parentheses *inside* search terms in some circumstances' do
    assert_equal({ bool: { must: [
                   { term: { 'namespaced_tags.name' => 'pinkie pie (cosplayer)' } },
                   { bool: { must_not: [
                     { term: { 'namespaced_tags.name' => 'fluttershy (pony)' } }
                   ] } },
                   { term: { 'namespaced_tags.name' => 'apple (fruit)' } }
                 ] } },
                 tags_parser('pinkie pie (cosplayer),(-fluttershy (pony),apple (fruit))').parsed)
  end

  test 'negates an AND expression if preceded by NOT op' do
    assert_equal({ bool: { must_not: [
                   { bool: { must: [
                     { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                     { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                   ] } }
                 ] } },
                 tags_parser('!(pinkie pie, twilight sparkle)').parsed)
  end

  test 'negates an OR expression if preceded by NOT op' do
    assert_equal({ bool: { must_not: [
                   { bool: { should: [
                     { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                     { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                   ] } }
                 ] } },
                 tags_parser('!(pinkie pie || twilight sparkle)').parsed)
  end

  test 'can negate a parenthesized subexpression linked by AND' do
    assert_equal({ bool: { must: [
                   { bool: { must_not: [
                     { bool: { should: [
                       { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                       { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                     ] } }
                   ] } },
                   { term: { 'namespaced_tags.name' => 'rarity' } }
                 ] } },
                 tags_parser('!(pinkie pie || twilight sparkle) && rarity').parsed)
  end

  test 'can negate a parenthesized subexpression linked by OR' do
    assert_equal({ bool: { should: [
                   { bool: { must_not: [
                     { bool: { should: [
                       { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                       { bool: { must: [
                         { bool: { must_not: [
                           { term: { 'namespaced_tags.name' => 'fluttershy' } }
                         ] } },
                         { term: { 'namespaced_tags.name' => 'apple bloom' } }
                       ] } }
                     ] } }
                   ] } },
                   { term: { 'namespaced_tags.name' => 'applejack' } }
                 ] } },
                 tags_parser('NOT (pinkie pie || !fluttershy && apple bloom) || applejack').parsed)
  end

  test 'supports parenthesized subexpressions' do
    assert_equal({ bool: { must: [
                   { bool: { should: [
                     { bool: { must: [
                       { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                       { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                     ] } },
                     { term: { 'namespaced_tags.name' => 'applejack' } }
                   ] } },
                   { term: { 'namespaced_tags.name' => 'apple bloom' } }
                 ] } },
                 tags_parser('((pinkie pie && twilight sparkle) || applejack) && apple bloom').parsed)
  end

  test 'can negate a whole complex expression' do
    assert_equal({ bool: { must_not: [
                   { bool: { must: [
                     { bool: { should: [
                       { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                       { term: { 'namespaced_tags.name' => 'twilight sparkle' } }
                     ] } },
                     { term: { 'namespaced_tags.name' => 'applejack' } }
                   ] } }
                 ] } },
                 tags_parser('!((pinkie pie || twilight sparkle) && applejack)').parsed)
  end

  test 'aliases defined fields to actual target indexes' do
    assert_equal({ term: { favourited_by_users: 'k_a' } },
                 tags_parser(
                   'faved_by:k_a',
                   allowed_fields: { literal: [:faved_by] },
                   field_aliases:  { faved_by: :favourited_by_users }
                 ).parsed)
  end

  test 'transforms values for specified fields and respective functions' do
    assert_equal({ term: { 'namespaced_tags.name' => 'k a' } },
                 tags_parser(
                   'k_a',
                   field_transforms: { 'namespaced_tags.name' => ->(x) { { term: { 'namespaced_tags.name' => x.sub('_', ' ') } } } }
                 ).parsed)

    assert_equal({ term: { emotion: '^_^' } },
                 tags_parser(
                   'emotion:happy',
                   allowed_fields:   { literal: [:emotion] },
                   field_transforms: { emotion: ->(x) { { term: { emotion: x.replace('^_^') } } } }
                 ).parsed)
  end

  test 'supports custom literal fields only when defined' do
    assert_equal({ bool: { should: [
                   { term: { uploader: 'k_a' } },
                   { term: { 'namespaced_tags.name' => 'artist:k-anon' } }
                 ] } },
                 tags_parser(
                   'uploader:k_a || artist:k-anon',
                   allowed_fields: { literal: [:uploader] }
                 ).parsed)
  end

  test 'supports fuzzy queries' do
    parser = tags_parser(
      'uploader:k_a~1.00 || artist:k-anon || "lyra hortstrings"~0.9',
      allowed_fields: { literal: [:uploader] }
    )

    assert_equal({ bool: { should: [
                   { fuzzy: { uploader: {
                     value:     'k_a',
                     fuzziness: 1.0
                   } } },
                   { term: { 'namespaced_tags.name' => 'artist:k-anon' } },
                   { fuzzy: { 'namespaced_tags.name' => {
                     value:     'lyra hortstrings',
                     fuzziness: 0.9
                   } } }
                 ] } },
                 parser.parsed)
    assert parser.requires_query
  end

  test 'supports boosting terms' do
    parser = tags_parser(
      'uploader:k_a^-1 || artist:k-anon || "lyra heartstrings"^5.3',
      allowed_fields: { literal: [:uploader] }
    )

    assert_equal({ bool: { should: [
                   { term: { uploader: {
                     value: 'k_a',
                     boost: -1
                   } } },
                   { term: { 'namespaced_tags.name' => 'artist:k-anon' } },
                   { term: { 'namespaced_tags.name' => {
                     value: 'lyra heartstrings',
                     boost: 5.3
                   } } }
                 ] } },
                 parser.parsed)
    assert parser.requires_query
  end

  test 'supports boosting fuzzy queries' do
    parser = tags_parser(
      'uploader:k_a~1.00^3 || artist:k-anon || "lyra hortstrings"^78~0.9',
      allowed_fields: { literal: [:uploader] }
    )

    assert_equal({ bool: { should: [
                   { fuzzy: { uploader: {
                     value:     'k_a',
                     boost:     3,
                     fuzziness: 1.0
                   } } },
                   { term: { 'namespaced_tags.name' => 'artist:k-anon' } },
                   { fuzzy: { 'namespaced_tags.name' => {
                     value:     'lyra hortstrings',
                     boost:     78,
                     fuzziness: 0.9
                   } } }
                 ] } },
                 parser.parsed)
    assert parser.requires_query
  end

  test 'supports range fields' do
    assert_equal({ bool: { must: [
                   { bool: { should: [
                     { range: { score: { gt: 100 } } },
                     { range: { upvotes: { gt: 100 } } }
                   ] } },
                   { term: { comment_count: 50 } }
                 ] } },
                 tags_parser(
                   '(score.gt:100 || upvotes.gt:100), comment_count:50',
                   allowed_fields: { integer: [:comment_count, :ponies, :score, :upvotes] }
                 ).parsed)
  end

  test 'handles nested subexpressions' do
    assert_equal({ bool: { should: [
                   { bool: { must: [
                     { bool: { should: [
                       { range: { score: { gt: 100 } } },
                       { range: { upvotes: { gt: 100 } } }
                     ] } },
                     { bool: { should: [
                       { term: { comment_count: 50 } },
                       { bool: { must_not: [
                         { bool: { must: [
                           { term: { 'namespaced_tags.name' => 'pinkie pie' } },
                           { term: { 'namespaced_tags.name' => 'cat' } }
                         ] } }
                       ] } }
                     ] } }
                   ] } },
                   { term: { favourited_by: 'pony pony' } }
                 ] } },
                 tags_parser(
                   '((score.gt:100 || upvotes.gt:100), (comment_count:50 || !(pinkie pie, cat))) || faved_by:pony pony',
                   allowed_fields: {
                     integer: [:comment_count, :ponies, :score, :upvotes],
                     literal: [:faved_by]
                   },
                   field_aliases:  { faved_by: :favourited_by }
                 ).parsed)
  end

  test 'handles NOT ops inside terms appropriately' do
    assert_equal({ term: { 'namespaced_tags.name' => 'a - b' } },
                 tags_parser('a - b').parsed)
  end

  test 'can search through a year' do
    assert_equal({ range: { created_at: {
                   gte: '2015-01-01T00:00:00Z'.to_time,
                   lt:  '2016-01-01T00:00:00Z'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through a year with a localized time zone' do
    assert_equal({ range: { created_at: {
                   gte: '2015-01-01T00:00:00+08:00'.to_time,
                   lt:  '2016-01-01T00:00:00+08:00'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015+08:00',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through a month' do
    assert_equal({ range: { created_at: {
                   gte: '2015-04-01T00:00:00Z'.to_time,
                   lt:  '2015-05-01T00:00:00Z'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-04',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through a month with a localized time zone' do
    assert_equal({ range: { created_at: {
                   gte: '2015-04-01T00:00:00-03:00'.to_time,
                   lt:  '2015-05-01T00:00:00-03:00'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-04-03:00',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through a day' do
    assert_equal({ range: { created_at: {
                   gte: '2015-04-01T00:00:00Z'.to_time,
                   lt:  '2015-04-02T00:00:00Z'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-04-01',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through a day with a localized time zone' do
    assert_equal({ range: { created_at: {
                   gte: '2015-04-01T00:00:00+08:00'.to_time,
                   lt:  '2015-04-02T00:00:00+08:00'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-04-01+08:00',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through an hour' do
    assert_equal({ range: { created_at: {
                   gte: '2015-04-01T01:00:00Z'.to_time,
                   lt:  '2015-04-01T02:00:00Z'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-04-01 01',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through an hour with a localized time zone' do
    assert_equal({ range: { created_at: {
                   gte: '2015-04-01T01:00:00-04:00'.to_time,
                   lt:  '2015-04-01T02:00:00-04:00'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-04-01 01-04:00',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through a minute' do
    assert_equal({ range: { created_at: {
                   gte: '2015-04-01T01:00:00Z'.to_time,
                   lt:  '2015-04-01T01:01:00Z'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-04-01 01:00',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through a minute with a localized time zone' do
    assert_equal({ range: { created_at: {
                   gte: '2015-04-01T01:00:00-04:00'.to_time,
                   lt:  '2015-04-01T01:01:00-04:00'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-04-01 01:00-04:00',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through a second' do
    assert_equal({ range: { created_at: {
                   gte: '2015-04-01T00:00:00Z'.to_time,
                   lt:  '2015-04-01T00:00:01Z'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-04-01 00:00:00',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through a second with a localized time zone' do
    assert_equal({ range: { created_at: {
                   gte: '2015-04-01T00:00:00+08:00'.to_time,
                   lt:  '2015-04-01T00:00:01+08:00'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-04-01 00:00:00+08:00',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'carries over overflow in time units for upper time boundaries' do
    assert_equal({ range: { created_at: {
                   gte: '2015-12-31T23:59:59+08:00'.to_time,
                   lt:  '2016-01-01T00:00:00+08:00'.to_time
                 } } },
                 tags_parser(
                   'created_at:2015-12-31 23:59:59+08:00',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through an explicit year range appropriately' do
    assert_equal({ range: { created_at: { lt: '2015-01-01T00:00:00Z'.to_time } } },
                 tags_parser(
                   'created_at.lt:2015',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end

  test 'can search through a more precise date range appropriately' do
    assert_equal({ range: { created_at: { gte: '2015-03-31T23:13:12Z'.to_time } } },
                 tags_parser(
                   'created_at.gte:2015-03-31T23:13:12',
                   allowed_fields: { date: [:created_at] }
                 ).parsed)
  end
end
