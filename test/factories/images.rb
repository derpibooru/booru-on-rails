# frozen_string_literal: true

require 'tempfile'
require 'fileutils'

FactoryBot.define do
  factory :image do
    ip { '192.168.0.50' }
    image do
      out = Tempfile.new(%w[test .png])
      FileUtils.cp(Rails.root.join('test', 'fixtures', 'image_files', 'test.png'), out.path)
      File.open(out)
    end
    disable_processing { true }
    tag_input { 'safe, test, test image' }
    factory :image_skips_validation do
      to_create { |instance| instance.save(validate: false) }
    end
    factory :processed_image do
      disable_processing { false }
      factory :dedupe_image_1 do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', 'dedupe_1.jpg')) }
      end
      factory :dedupe_image_2 do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', 'dedupe_3.jpg')) }
      end
      factory :gif_first_frame_incorrect_size do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', '232093.gif')) }
      end
      factory :vector do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', '1131290.svg')) }
      end
      factory :jpeg_exif_orientation do
        source_url { Rails.root.join('test', 'fixtures', 'image_files', 'exif_orientation.jpg') }
        image do
          out = Tempfile.new(%w[exif .jpg])
          FileUtils.cp(source_url, out.path)
          File.open(out)
        end
      end
      factory :explicit_image do
        tag_input { 'explicit, test, test image' }
      end
      factory :spoilered_image do
        after(:create) do |i|
          i.add_tags [create(:spoiler_tag)]
          i.save
        end
      end
      factory :pinkie_spy_1 do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', 'dedupe_anim.gif')) }
        tag_input { 'safe, pinkie pie, spy' }
      end
      factory :pinkie_spy_2 do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', 'dedupe_anim.png')) }
        tag_input { 'safe, pinkie pie, spy' }
      end
      factory :pinkie_not_spy do
        # (It actually uses the default Derpy image but without copying to a temp area.)
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', 'test.png')) }
        tag_input { 'safe, pinkie pie, spy' }
      end
      factory :nightmare_dupe_1 do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', 'dedupe_evade_1.jpeg')) }
        tag_input { 'safe, nightmare moon, nightmare dupe' }
      end
      factory :dupe_1 do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', 'dedupe_near_3.jpg')) }
        tag_input { 'safe, nightmare moon, nightmare dupe' }
      end
      factory :dupe_2 do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', 'dedupe_near_4.jpg')) }
        tag_input { 'safe, nightmare moon, nightmare dupe' }
      end
      factory :octavia_1 do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', 'test.gif')) }
        tag_input { 'safe, octavia, animated' }
      end
      factory :octavia_2 do
        image { File.open(Rails.root.join('test', 'fixtures', 'image_files', 'test.jpg')) }
        tag_input { 'safe, octavia, vinyl scratch' }
      end
    end
  end
end
