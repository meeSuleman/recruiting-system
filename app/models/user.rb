class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :validatable,
  :jwt_authenticatable, :lockable,
  jwt_revocation_strategy: JwtDenylist

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { message: "is already associated with an admin." }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  def name
    "#{first_name} #{last_name}"
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name email contact]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
