class User
  include Mongoid::Document
  include ActiveModel::SecurePassword
  include Mongoid::Timestamps
  
  field :name, type: String
  field :email, type: String
  field :password_digest, type: String
  field :remember_digest, type: String
  field :admin,	type: Boolean, default: false
  field :activated,	type: Boolean, default: false
  field :activation_digest, type: String
  field :activated_at, type: Time
  field :reset_digest, type: String
  field :reset_sent_at, type: Time

  has_many :microposts, dependent: :destroy
  has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "follower_id",
                                  dependent:   :destroy,
                                  inverse_of: :follower
  has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy,
                                   inverse_of: :followed


  attr_accessor :remember_token, :activation_token, :reset_token

  index({ email: 1 }, { unique: true })

  before_save   :downcase_email
  before_create :create_activation_digest

  has_secure_password
  validates :name,  presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # Returns the hash digest of the given string.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token.
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # Forgets a user.
  def forget
    update_attribute(:remember_digest, nil)
  end

  # Activates an account.
  def activate
    update_attributes(activated: true, activated_at: Time.zone.now)
  end

  # Sends activation email.
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  # Sets the password reset attributes.
  def create_reset_digest
    self.reset_token = User.new_token
    update_attributes(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  # Sends password reset email.
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Returns true if a password reset has expired.
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # Defines a proto-feed.
  # See "Following users" for the full implementation.
  def feed
    microposts
  end

  # Follows a user.
  def follow(other_user)
    active_relationships.create(follower_id: self.id, followed_id: other_user.id)
  end

  # Unfollows a user.
  def unfollow(other_user)
    relation = active_relationships.where(follower_id: self.id, followed_id: other_user.id).first
    if not relation.nil?
      relation.destroy
    end
  end

  # Returns true if the current user is following the other user.
  def following?(other_user)
    not active_relationships.where(follower_id: self.id, followed_id: other_user.id).empty?
  end

  def followers_include?(other_user)
    not passive_relationships.where(follower_id: other_user.id, followed_id: self.id).empty?
  end

  def following_count
    active_relationships.count
  end

  def followers_count
    passive_relationships.count
  end

  def following
    id_list= []
    active_relationships.each do |f|
      id_list << f.followed_id
    end
    User.where(:id.in => id_list)
  end

  def followers
    id_list= []
    passive_relationships.each do |f|
      id_list << f.follower_id
    end
    User.where(:id.in => id_list)
  end

  private

    # Converts email to all lower-case.
    def downcase_email
      email.downcase!
    end

    # Creates and assigns the activation token and digest.
    def create_activation_digest
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
end
