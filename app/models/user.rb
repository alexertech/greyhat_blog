# frozen_string_literal: true

class User < ApplicationRecord
  validates :public_name, presence: true, length: { minimum: 1 }
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, # :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :lockable,
         :timeoutable,
         :trackable
  
  has_many :posts, dependent: :destroy
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [120, 120], format: :webp
    attachable.variant :medium, resize_to_fill: [200, 200], format: :webp
  end
  
  def display_name
    public_name.presence || email.split('@').first.split('.').first.capitalize
  end
end
