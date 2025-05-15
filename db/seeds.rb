# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

user = User.new(email: 'alex@dev', password: 'holaholahola')
user.save

Page.new(id: 1, name: 'index').save!
Page.new(id: 2, name: 'about').save!
Page.new(id: 3, name: 'services').save!

(1..3).each do |n|
  post = Post.new(title: "Blog post #{n}",
                  body: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry.')
  post.image.attach(io: File.new("#{Rails.root}/app/assets/images/new_main.jpg"), content_type: 'image/jpeg',
                    filename: 'banner.jpg')
  post.save!
end
