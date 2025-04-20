class InvitationsController < ApplicationController
  before_action :authenticate_user!, only: [ :create ]

  def create
    @invitation = Invitation.new(invitation_params.merge(
      status: "pending",
      expires_at: 1.day.from_now
    ))

    # Create user with temporary password
    temp_password = SecureRandom.hex(8)
    user = User.new(
      email: @invitation.email,
      password: temp_password,
      password_confirmation: temp_password,
      invite_status: "pending"
    )

    if User.exists?(email: @invitation.email)
      error_response("This email is already associated with an admin.")
    else
      ActiveRecord::Base.transaction do
        user.save!
        @invitation.save!
        UserMailer.invitation_email(@invitation).deliver_later
        success_response("Invitation sent successfully", @invitation)
      end
    end
  end

  def accept
    @invitation = Invitation.find_by!(token: params[:id])
    @invitation&.check_expiration

    if @invitation&.pending?
      frontend_url = "https://app.pinkcollar.live/accept-invite/#{params[:id]}"
      redirect_to frontend_url
    else
      error_response("Invalid or expired invitation")
    end
  end

  def register_invited_user
    @invitation = Invitation.find_by!(token: params[:token])
    @invitation&.check_expiration

    if @invitation&.pending?
      user = @invitation.invited_user
      # Use Devise's reset password method instead of regular update
      if user.reset_password(params[:user][:password], params[:user][:password_confirmation])
        user.update!(user_params.merge(invite_status: "accepted"))
        @invitation.update(status: "accepted")
        success_response("User registered successfully", user)
      else
        error_response(user.errors.full_messages.uniq.to_sentence&.humanize)
      end
    else
      error_response("Invalid or expired invitation")
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :contact)
  end


  def invitation_params
    params.require(:invitation).permit(:email)
  end
end
