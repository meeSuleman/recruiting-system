class UserMailer < Devise::Mailer
  default from: "Pink Collar Team<info@pinkcollar.live>"
  layout "mailer"

  def reset_password_instructions(user, token, opts = {})
    @user = user
    @token = token
    @reset_password_url = edit_user_password_url(reset_password_token: @token)

    mail(
      to: @user.email,
      subject: "Reset Password Instructions"
    )
  end

  def invitation_email(invitation)
    @invitation = invitation
    @url = accept_invitation_url(id: @invitation.token, email: @invitation.email)

    mail(
      to: @invitation.email,
      subject: "Invitation to join Admin Panel"
    )
  end
end
