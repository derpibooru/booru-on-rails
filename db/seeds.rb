# frozen_string_literal: true

puts '---- Creating elasticsearch indexes'
Image.__elasticsearch__.create_index!
Comment.__elasticsearch__.create_index!
Gallery.__elasticsearch__.create_index!
Tag.__elasticsearch__.create_index!
Post.__elasticsearch__.create_index!
Report.__elasticsearch__.create_index!

resources = YAML.load_file Rails.root.join('db', 'seeds.yml')
rating_tags = YAML.load_file(Rails.root.join('config', 'booru', 'tag.yml'))[:rating_tags]

puts '---- Generating rating tags'
rating_tags.each do |tag_name|
  tag = Tag.new(name: tag_name)
  tag.set_namespaced_names!
  tag.set_slug
  tag.save!
rescue StandardError => ex
  puts "Couldn't create #{tag_name}, already exists?"
  puts ex
end

puts '---- Generating system filters'
resources['system_filters'].each do |filter|
  spoilered = filter['spoilered'].map { |tag| Tag.find_by(name: tag).id } rescue []
  hidden = filter['hidden'].map { |tag| Tag.find_by(name: tag).id } rescue []
  Filter.create! name: filter['name'], description: filter['description'],
                 spoilered_tag_ids: spoilered, hidden_tag_ids: hidden, system: true
  puts "#{filter['name']}: spoilered #{spoilered}, hidden #{hidden}"
rescue StandardError => ex
  puts "Couldn't create filter, already exists?"
  puts ex
end

puts '---- Generating forums'
resources['forums'].each do |forum|
  f = Forum.find_or_initialize_by(short_name: forum['short_name'])
  f.update(name: forum['name'], description: forum['description'])
  f.update_attribute(:access_level, forum['access_level']) if forum['access_level']
  f.save!
  puts "#{forum['name']} [#{forum['short_name']}]"
rescue StandardError => ex
  puts "Couldn't create forum, already exists?"
  puts ex
end

puts '---- Generating users'
resources['users'].each do |user|
  User.create! name: user['name'], email: user['email'],
               password: user['password'], password_confirmation: user['password'], role: user['role']
  puts "#{user['name']} (role: #{user['role']}) with password '#{user['password']}' and email: '#{user['email']}'. Change these upon login!"
rescue StandardError => ex
  puts "Couldn't create user, already exists?"
  puts ex
end

require_relative 'seeds_development' if ENV['DEV_SEED'] == 'y'

puts '---- Done.'
puts 'Start Sidekiq to generate image thumbnails (you can use the application in the meantime).'
