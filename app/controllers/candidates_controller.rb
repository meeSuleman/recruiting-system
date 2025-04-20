require "csv"

class CandidatesController < ApplicationController
  include ActionController::MimeResponds
  before_action :set_candidate, only: [ :show ]
  before_action :authenticate_user!, except: [ :create ]

  def index
    base_scope = filtered_candidates
    @q = base_scope.ransack(
      first_name_or_last_name_or_contact_number_or_email_or_address_or_city_or_institute_or_current_employer_cont: params[:search],
      s: params[:q]&.dig(:s) || params[:sort]
    )
    result = @q.result
    result = result.distinct if params[:search].present?

    if params[:export]&.to_s&.downcase == "true"
      csv_data = result.select(Candidate.column_names - [ "id", "created_at", "updated_at", "longitude", "latitude" ])
        .as_json(except: [ :id ])
      success_response("CSV data generated successfully", {
        csv_data: csv_data,
        filename: "candidates-#{Date.today}.csv"
      })
    else
      # For regular index, return paginated data
      @pagy, @candidates = pagy(result, limit: 12)
      success_response("Fetched candidates successfully", {
        candidates: @candidates,
        pagination: pagy_metadata(@pagy),
        sorting: {
          experience_options: Candidate.experiences.keys,
          current_sort: @q.sorts.map(&:name)
        }
      })
    end
  end

  def show
    candidate_details = @candidate.as_json.merge(url_details: {
      resume_url: @candidate.resume.attached? ? url_for(@candidate.resume) : url_for(@candidate.resume_image),
      photo_url: @candidate.photo.attached? ? url_for(@candidate.photo) : nil,
      intro_video_url: @candidate.intro_video.attached? ? url_for(@candidate.intro_video) : nil
    })
    success_response("Fetched candidate info successfully", candidate_details)
  end

  def create
    @candidate = Candidate.new(candidate_params.merge(industries: params[:candidate][:industries].values))
    @candidate.save!
    success_response("Candidate created successfully", @candidate)
  end

  def destroy
    @candidate = Candidate.find(params[:id])
    @candidate.destroy!
    success_response("Candidate deleted successfully", @candidate)
  end


  def validate_email
    email = params[:email]&.strip

    if email.blank?
      return error_response("Email is required", status: :unprocessable_entity)
    end

    # Check if email format and mx records are valid
    validator = ValidEmail2::Address.new(email)
    unless validator.valid? && validator.valid_mx? && validator.valid_strict_mx?
      return error_response("Email address does not exist", status: :unprocessable_entity)
    end

    # Check if email already exists in database
    if Candidate.exists?(email: email)
      return error_response("Applicant already register with this email", status: :unprocessable_entity)
    end

    success_response("Email is valid and available")
  end

  private

  def set_candidate
    @candidate = Candidate.find(params[:id])
  end

  def candidate_params
    params.require(:candidate).permit(
      :first_name, :last_name, :email, :contact_number,
      :dob, :education, :experience, :expected_salary,
      :career_phase, :additional_notes, :resume, :resume_image, :photo,
      :institute, :intro_video, :currently_employed,
      :current_salary, :current_employer, :function,
      :address, :city, :state
    )
  end

  def filtered_candidates
    scope = Candidate.all.order(created_at: :desc)

    # Apply filters if they exist
    scope = scope.where(filter_conditions) if filter_conditions.present?
    scope = apply_text_search_filters(scope)
    scope = apply_industry_filter(scope) if params[:industries].present?

    scope
  end

  def filter_conditions
    conditions = {}

    # Collect all exact match conditions in a single hash
    conditions[:experience] = params[:experience] if params[:experience].present?
    conditions[:function] = params[:function] if params[:function].present?
    conditions[:expected_salary] = params[:expected_salary] if params[:expected_salary].present?
    conditions[:current_salary] = params[:current_salary] if params[:current_salary].present?
    conditions[:career_phase] = params[:career_phase] if params[:career_phase].present?

    conditions
  end

  def apply_text_search_filters(scope)
    if params[:institute].present?
      scope = scope.where("institute ILIKE ?", "%#{params[:institute]}%")
    end

    if params[:city].present?
      scope = scope.where("city ILIKE ?", "%#{params[:city]}%")
    end

    scope
  end

  def apply_industry_filter(scope)
    return scope unless params[:industries].present?

    scope.where("industries && ARRAY[?]::text[]", params[:industries])
  end

  def sanitize_sql_like(string)
    return "" if string.blank?
    string.gsub(/[\\%_]/) { |m| "\\#{m}" }
  end

  def ransack_params
    params.fetch(:q, {}).permit(:s)
  end
end
