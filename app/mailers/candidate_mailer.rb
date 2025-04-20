class CandidateMailer < ApplicationMailer
  def application_confirmation
    @candidate = params[:candidate]
    @application_date = @candidate.created_at.strftime("%B %d, %Y")

    mail(
      to: @candidate.email,
      subject: "Application Submitted Successfully"
    )
  end
end
