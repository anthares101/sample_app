class Micropost
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, type: String

  belongs_to :user
  
  default_scope -> { order(created_at: :desc) }
  index({ user_id: 1, created_at: 1 })

  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }

end
