# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include ExceptionHandler
  # before_action :configure_sign_in_params, only: [:create]
  respond_to :json
  rescue_from JWT::ExpiredSignature, with: :handle_expired_token

  def create
    user = User.find_by!(email: params[:user][:email])
    unless user.is_active
      msg = "Your account is not active. Please contact admin for more information."
      error_response(msg, msg)
    else
      super
    end
  end

  private

  def handle_expired_token
    error_response("Your session has expired. Please log in again.", status: :unauthorized)
  end

  def respond_to_on_destroy
    if current_user
      success_response("Logged out successfully!")
    else
      error_response("Couldn't find an active session!", status: :unauthorized)
    end
  end

  def respond_with(resource, _opts = {})
    if resource.errors.blank?
      success_response(
        "Logged in successfully!",
        {
          user: resource,
          token: Warden::JWTAuth::UserEncoder.new.call(resource, :user, nil).first
        }
      )
    else
      error_response(resource.errors.full_messages.uniq.to_sentence&.humanize)
    end
  end
end
