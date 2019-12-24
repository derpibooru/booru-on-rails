# frozen_string_literal: true

require 'shellwords'
require 'securerandom'

class Captcha
  attr_reader :image_base64, :solution, :solution_id

  NUMBERS = %w[1 2 3 4 5 6].freeze
  IMAGES  = %w[1 2 3 4 5 6].freeze

  CAPTCHA_ASSETS_BASE_PATH = 'app/assets/images/captcha'

  NUMBER_FILES = {
    '1' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, '1.png').to_s.shellescape,
    '2' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, '2.png').to_s.shellescape,
    '3' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, '3.png').to_s.shellescape,
    '4' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, '4.png').to_s.shellescape,
    '5' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, '5.png').to_s.shellescape,
    '6' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, '6.png').to_s.shellescape
  }.freeze

  IMAGE_FILES = {
    '1' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, 'i1.png').to_s.shellescape,
    '2' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, 'i2.png').to_s.shellescape,
    '3' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, 'i3.png').to_s.shellescape,
    '4' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, 'i4.png').to_s.shellescape,
    '5' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, 'i5.png').to_s.shellescape,
    '6' => Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, 'i6.png').to_s.shellescape
  }.freeze

  BACKGROUND_FILE = Rails.root.join(CAPTCHA_ASSETS_BASE_PATH, 'background.png').to_s.shellescape

  GEOMETRY = {
    1 => '+0+0',   2 => '+120+0',   3 => '+240+0',
    4 => '+0+120', 5 => '+120+120', 6 => '+240+120',
    7 => '+0+240', 8 => '+120+240', 9 => '+240+240'
  }.freeze

  DISTORTION_1 = [
    '-implode .1',
    '-implode -.1'
  ].freeze

  DISTORTION_2 = [
    '-swirl 10',
    '-swirl -10',
    '-swirl 20',
    '-swirl -20'
  ].freeze

  DISTORTION_3 = [
    '-wave 5x180',
    '-wave 5x126',
    '-wave 10x180',
    '-wave 10x126'
  ].freeze

  def initialize
    @solution = NUMBERS.zip(IMAGES.shuffle).to_h

    # 3x3 render grid
    grid = [*NUMBERS, nil, nil, nil].shuffle

    # Base arguments
    imagemagick_cmd = [
      'convert -page 360x360',
      BACKGROUND_FILE
    ]

    # Add individual grid tiles
    grid.each_with_index do |num, i|
      next if num.nil?

      imagemagick_cmd.push("\\( #{IMAGE_FILES[@solution[num]]} \\) -geometry #{GEOMETRY[i + 1]} -composite")
      imagemagick_cmd.push("\\( #{NUMBER_FILES[num]} \\) -geometry #{GEOMETRY[i + 1]} -composite")
    end

    imagemagick_cmd.concat([DISTORTION_1.sample, DISTORTION_2.sample, DISTORTION_3.sample].shuffle)
    imagemagick_cmd.push('-quality 8 jpeg:-')

    @image_base64 = `#{imagemagick_cmd.join(' ')} | base64 -w 0`.strip

    # Store solution in redis so that we can prevent reuse
    @solution_id = "cp#{SecureRandom.hex(12)}"
    $redis.set(@solution_id, @solution.to_json)
    $redis.expire(@solution_id, 10.minutes)
  end

  def self.validate(solution_id, solution)
    # Delete key immediately. This may race, but the
    # impact should be minimal if a race succeeds.
    sol = $redis.get(solution_id)
    $redis.del(solution_id)

    return false if sol.blank?

    sol = JSON.parse(sol)

    # Ruby hash equality tests key/value equality, but not
    # key order equality, so this works.
    sol == solution
  rescue StandardError
    false
  end
end

module CaptchaVerifier
  def verify_captcha
    return true if !$flipper[:captcha].enabled?

    Captcha.validate(params[:_captcha_id], params[:_captcha_sln])
  end
end
