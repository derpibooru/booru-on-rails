# frozen_string_literal: true

require 'test_helper'
require 'simpletextile'

class SimpleTextileTest < ActiveSupport::TestCase
  attr_accessor :st

  setup do
    @st = SimpleTextile.new
  end

  test 'should output plain single-line text unmodified' do
    assert_equal 'hello world', st.default_match.parse('hello world')
  end

  test 'should insert linebreaks on newlines' do
    text = "hello\nworld"
    output = "hello<br>\nworld"
    assert_equal output, st.default_match.parse(text)
  end

  test "should escape ' properly" do
    text = "'hello'"
    output = '&#8217;hello&#8217;'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should wrap *text* with <strong>' do
    text = '*hello*'
    output = '<strong>hello</strong>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should wrap _text_ with <em>' do
    text = '_hello_'
    output = '<em>hello</em>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should wrap @text@ with <code>' do
    text = '@hello@'
    output = '<code>hello</code>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should wrap +text+ with <ins>' do
    text = '+hello+'
    output = '<ins>hello</ins>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should wrap ^text^ with <sup>' do
    text = '^hello^'
    output = '<sup>hello</sup>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should wrap -text- with <del>' do
    text = '-hello-'
    output = '<del>hello</del>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should wrap ~text~ with <sub>' do
    text = '~hello~'
    output = '<sub>hello</sub>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should wrap *text* with <strong> with newlines' do
    text = "*hello\nworld*"
    output = "<strong>hello<br>\nworld</strong>"
    assert_equal output, st.default_match.parse(text)
  end

  test 'should wrap *+text+* with <strong><ins>' do
    text = '*+hello world+*'
    output = '<strong><ins>hello world</ins></strong>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should wrap _-text-_ with <em><del>' do
    text = '_-hello world-_'
    output = '<em><del>hello world</del></em>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should convert !http://some-uri! into an <img> tag' do
    text = '!http://hello!'
    output = Regexp.new('<span class="imgspoiler"><img src=".*hello.*"></span>')
    assert_match output, st.default_match.parse(text)
  end

  test 'should convert !//some-uri! into an <img> tag' do
    text = '!//hello!'
    output = Regexp.new('<span class="imgspoiler"><img src=".*hello.*"></span>')
    assert_match output, st.default_match.parse(text)
  end

  test 'should convert !http://some-uri.com/test.png(title)! into an <img> tag' do
    text = '!http://hello.com/test.png(title)!'
    output = Regexp.new('<span class="imgspoiler"><img src=".*hello\.com.*test\.png" title="title" alt="title"></span>')
    assert_match output, st.default_match.parse(text)
  end

  test 'should convert !http://some-uri.com/test.png!:http://some-uri.com to an <img> tag wrapped in an <a> tag' do
    text = '!http://hello.com/test.png!:http://some-uri.com'
    output = Regexp.new('<a href="http://some-uri\.com"><span class="imgspoiler"><img src=".*hello\.com.*test\.png"></span></a>')
    assert_match output, st.default_match.parse(text)
  end

  test 'should leave quotes alone on their own' do
    text = 'this "is quoted" nicely'
    assert_equal text, st.default_match.parse(text)
  end

  test 'should convert "text":http://url.com to a link' do
    text = '"text":http://url.com'
    output = '<a href="http://url.com">text</a>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should convert [spoiler]text[/spoiler] to <span class="spoiler">text</span>' do
    text = '[spoiler]text[/spoiler]'
    output = '<span class="spoiler">text</span>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should convert [bq]text[/bq] to <blockquote>text</blockquote>' do
    text = '[bq]text[/bq]'
    output = '<blockquote>text</blockquote>'
    assert_equal output, st.default_match.parse(text)
  end

  test 'should convert all instances of [bq]text[/bq] to <blockquote>text</blockquote>' do
    text = '[bq]text[bq]text[bq="pinkie"]derp[/bq][/bq][/bq]'
    output = '<blockquote>text<blockquote>text<blockquote title="pinkie">derp</blockquote></blockquote></blockquote>'
    assert_equal output, st.default_match.parse(text)
  end
end
