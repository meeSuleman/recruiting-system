class Invitation < ApplicationRecord
  # Associations
  belongs_to :invited_user, class_name: "User", foreign_key: :email, primary_key: :email, optional: true

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { message: "is already associated with an admin." }
  validates :token, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending accepted expired] }

  enum status: { pending: 0, accepted: 1, expired: 2 }

  # Callbacks
  before_validation :generate_token, on: :create

  def check_expiration
    if pending? && expires_at < Time.current
      ActiveRecord::Base.transaction do
        # Find and destroy the associated user first
        if invited_user.present? && invited_user.invite_status == "pending"
          invited_user.destroy!
        end
        # Then mark invitation as expired
        update!(status: :expired)
      end
    end
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(16)
  end
end
