# frozen_string_literal: true

resources = YAML.load_file Rails.root.join('db', 'seeds_development.yml')

REQUEST_ATTRIBUTES = { fingerprint: 'c1836832948',
                       ip: '203.0.113.0', user_agent: 'Hopefully not IE', referrer: 'localhost' }.freeze

puts '---- Generating users'
resources['users'].each do |user|
  User.create! name: user['name'], email: user['email'],
               password: user['password'], password_confirmation: user['password'], role: user['role']
  puts "#{user['name']} (role: #{user['role']}) with password '#{user['password']}' and email '#{user['email']}'"
end

def create_image
  image = Image.new
  yield image
  image.assign_attributes REQUEST_ATTRIBUTES.merge(user: User.all.sample)
  image.save
end

puts '---- Generating images'
Dir.foreach(Rails.root.join('test', 'fixtures', 'image_files')).each do |image_file|
  next if ['.', '..'].include? image_file

  create_image do |image|
    image.tag_input = resources['tags'].sample(2).push('safe').join(',')
    image.image = File.open Rails.root.join('test', 'fixtures', 'image_files', image_file)
    image.description = 'Inserted from test fixtures'
  end
end

puts '---- Inserting remote images'
resources['remote_images'].each do |remote_image|
  create_image do |image|
    image.tag_input = remote_image['tags']
    image.remote_image_url = remote_image['url']
    image.description = remote_image['description']
  end
end rescue nil

puts '---- Generating comments for image #0'
resources['comments'].each do |text|
  Comment.create!({ body: text, image: Image.first, user: User.all.sample,
                    anonymous: [true, false].sample }.merge(REQUEST_ATTRIBUTES))
end

puts '---- Generating forum posts'
resources['forum_posts'].each do |forum|
  forum.each_pair do |forum_name, topics|
    topics.each do |t|
      title = t.first[0]
      posts = t.first[1]
      op = User.all.sample
      topic = Topic.create! title: title, forum: Forum.find_by(short_name: forum_name),
                            user: op, anonymous: false
      Post.create!({ topic: topic, body: posts.shift, user: op,
                     anonymous: false }.merge(REQUEST_ATTRIBUTES))
      posts.each do |post_body|
        Post.create!({ topic: topic, body: post_body, user: User.all.sample,
                       anonymous: [true, false].sample }.merge(REQUEST_ATTRIBUTES))
      end
    end
  end
end
