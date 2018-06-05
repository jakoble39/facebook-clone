class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:facebook, :github]

  has_one :profile, dependent: :destroy
  # has_many :profiles
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :sent_requests, foreign_key: :requester_id, class_name: 'Request', dependent: :destroy
  has_many :received_requests, foreign_key: :requestee_id, class_name: 'Request', dependent: :destroy
  has_many :requestees, through: :sent_requests, dependent: :destroy
  has_many :requesters, through: :received_requests, dependent: :destroy

  after_create :make_profile


  def friends
     @friends = self.requesters.where('requests.accepted = ?', 1) |
                self.requestees.where('requests.accepted = ?', 1)
     @friends.sort do |a, b|
        a.created_at <=> b.created_at
     end
  end

  def friend_ids
    @friend_ids = self.requesters.where('requests.accepted = ?', 1).select(:id) |
               self.requestees.where('requests.accepted = ?', 1).select(:id)
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?

      end
    end
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0,20]
      user.first_name = auth.info.name.split(" ")[0]
      user.last_name = auth.info.name.split(" ")[1]
      user.image = auth.info.image # assuming the user model has an image
    end
  end

  private

  def make_profile
    # self.create_profile(avatar_file_name: self.image)
    self.create_profile
  end


end
