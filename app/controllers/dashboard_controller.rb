class DashboardController < ApplicationController
  before_action :authenticate_user!, except: [ :health_check ]
  before_action :set_date_range, only: [ :index ]
  before_action :set_dashboard_counts, only: [ :index ]

  def index
    @dashboard_data = {
      total_applicants: {
        value: total_applicants,
        trend: date_range_present? ? calculate_trend(total_applicants, previous_total_applicants) : nil
      },
      upload_rates: {
        resume: {
          value: calculate_percentage(@resume_count, total_applicants),
          trend: date_range_present? ? calculate_trend(
            calculate_percentage(@resume_count, total_applicants),
            calculate_percentage(@previous_resume_count, previous_total_applicants)
          ) : nil
        },
        video: {
          value: calculate_percentage(@video_count, total_applicants),
          trend: date_range_present? ? calculate_trend(
            calculate_percentage(@video_count, total_applicants),
            calculate_percentage(@previous_video_count, previous_total_applicants)
          ) : nil
        },
        profile_completion: {
          value: calculate_percentage(@completed_profiles_count, total_applicants),
          trend: date_range_present? ? calculate_trend(
            calculate_percentage(@completed_profiles_count, total_applicants),
            calculate_percentage(@previous_completed_profiles_count, previous_total_applicants)
          ) : nil
        }
      },
      generational_breakdown: generational_breakdown,
      function_distribution: function_distribution,
      drop_off_rate: {
        total_applicants: {
          count: total_applicants,
          percentage: 100
        },
        resume_uploads: {
          count: @resume_count,
          percentage: calculate_percentage(@resume_count, total_applicants)
        },
        video_uploads: {
          count: @video_count,
          percentage: calculate_percentage(@video_count, total_applicants)
        },
        completed_profiles: {
          count: @completed_profiles_count,
          percentage: calculate_percentage(@completed_profiles_count, total_applicants)
        }
      },
      top_cities: top_cities,
      resume_to_video_ratio: calculate_resume_to_video_ratio,
      date_range: { start_date: @start_date, end_date: @end_date }
    }

    success_response("Dashboard loaded successfully", @dashboard_data)
  end

  def admins_list
    base_scope = User.where.not(id: current_user.id).order(created_at: :desc)
    base_scope = base_scope.where(invite_status: params[:invite_status]) if %w[pending accepted deactivated].include?(params[:invite_status])

    @q = base_scope.ransack(
      first_name_or_last_name_or_contact_or_email_cont: params[:search]
    )

    result = @q.result
    result = result.distinct if params[:search].present?

    if params[:export]&.to_s&.downcase == "true"
      csv_data = result.select(User.column_names - [ "id", "created_at", "updated_at" ])
        .as_json(except: [ :id ])
      success_response("CSV data generated successfully", {
        csv_data: csv_data,
        filename: "admins-#{Date.today}.csv"
      })
    else
      @pagy, @admins = pagy(result, overflow: :last_page)

      success_response("Fetched admins successfully", {
        admins: @admins,
        pagination: pagy_metadata(@pagy)
      })
    end
  end

  def show_admin
    @admin = User.find(params[:id])
    success_response("Fetched admin successfully", @admin)
  end

  def deactivate_admin
    @admin = User.find(params[:id])
    @admin.update!(is_active: false, invite_status: "deactivated")
    success_response("Admin deactivated successfully", @admin)
  end

  def activate_admin
    @admin = User.find(params[:id])
    if @admin.invite_status == "pending"
      error_response("Invite has not been accepted for this admin yet.")
    else
      @admin.update!(is_active: true, invite_status: "accepted")
      success_response("Admin activated successfully", @admin)
    end
  end

  def delete_admin
    @admin = User.find(params[:id])
    user_invite = Invitation.find_by(email: @admin.email)
    ActiveRecord::Base.transaction do
      user_invite.destroy! if user_invite.present?
      @admin.destroy!
      success_response("Admin deleted successfully", @admin)
    end
  end

  def health_check
    success_response("Pink Collar is running smoothly", {})
  end

  private

  def set_date_range
    if params[:start_date].present? && params[:end_date].present?
      @start_date = DateTime.parse(params[:start_date]).beginning_of_day
      @end_date = DateTime.parse(params[:end_date])
    end
  rescue Date::Error
    error_response("Invalid date format")
  end

  def set_dashboard_counts
    @attachment_counts = get_attachment_counts(filtered_candidates)
    @resume_count = @attachment_counts.count { |c| c.has_resume > 0 }
    @video_count = @attachment_counts.count { |c| c.has_video > 0 }
    @completed_profiles_count = @attachment_counts.count { |c| c.is_complete == 1 }

    if date_range_present?
      previous_candidates = Candidate.where(created_at: previous_period_start_date..previous_period_end_date)
      @previous_attachment_counts = get_attachment_counts(previous_candidates)
      set_previous_counts
    end
  end

  def set_previous_counts
    @previous_resume_count = @previous_attachment_counts.count { |c| c.has_resume > 0 }
    @previous_video_count = @previous_attachment_counts.count { |c| c.has_video > 0 }
    @previous_completed_profiles_count = @previous_attachment_counts.count { |c| c.is_complete == 1 }
  end

  def calculate_percentage(count, total)
    return 0 if total.zero?
    (count.to_f / total * 100).round(2)
  end

  def filtered_candidates
    @filtered_candidates ||= begin
      candidates = Candidate.all

      # Date range filter
      if @start_date.present? && @end_date.present?
        candidates = candidates.where(created_at: @start_date..@end_date)
      end

      # Function filter
      if params[:function].present?
        candidates = candidates.where(function: params[:function])
      end

      # Industry filter
      if params[:industry].present?
        industries = params[:industry].is_a?(Array) ? params[:industry] : [ params[:industry] ]
        candidates = candidates.where("industries && ARRAY[?]::text[]", industries)
      end

      candidates
    end
  end

  def total_applicants
    @total_applicants ||= filtered_candidates.count
  end

  def generational_breakdown
    @generational_breakdown ||= begin
      results = filtered_candidates.select(<<-SQL)
        CASE
          WHEN EXTRACT(YEAR FROM dob) BETWEEN 2013 AND 2025 THEN 'Alpha'
          WHEN EXTRACT(YEAR FROM dob) BETWEEN 1997 AND 2012 THEN 'Gen Z'
          WHEN EXTRACT(YEAR FROM dob) BETWEEN 1981 AND 1996 THEN 'Millennials'
          WHEN EXTRACT(YEAR FROM dob) BETWEEN 1965 AND 1980 THEN 'Gen X'
          WHEN EXTRACT(YEAR FROM dob) BETWEEN 1946 AND 1964 THEN 'Baby Boomers'
        END as generation,
        COUNT(*) as count
      SQL
      .group("generation")
      .having("COUNT(*) > 0")

      results.each_with_object({}) do |result, hash|
        hash[result.generation] = {
          count: result.count,
          percentage: calculate_percentage(result.count, total_applicants)
        }
      end
    end
  end

  def function_distribution
    @function_distribution ||= begin
      function_distribution = {}

      # Use pluck to efficiently fetch only needed columns
      candidates_data = filtered_candidates.pluck(:industries, :function)

      # First, group by function and count total applicants per function
      candidates_data.each do |industries, function|
        next if function.blank?
        function_key = function.presence
        function_distribution[function_key] ||= { applicants_count: 0, industries: Hash.new(0) }
        function_distribution[function_key][:applicants_count] += 1

        # Then count industries for each function
        industries&.each do |industry|
          next if industry.blank?
          industry_key = "#{industry}_applicants"
          function_distribution[function_key][:industries][industry_key] += 1
        end
      end

      function_distribution
    end
  end

  def calculate_resume_to_video_ratio
    total_parts = total_applicants + @video_count
    return { resume: 0, video: 0 } if total_parts.zero?

    {
      resume: ((total_applicants.to_f / total_parts) * 100).round(2),
      video: ((@video_count.to_f / total_parts) * 100).round(2)
    }
  end

  def top_cities
    @top_cities ||= begin
      cities_data = filtered_candidates
        .group(:city, :latitude, :longitude)
        .count
        .map do |city_coords, count|
          city, lat, lng = city_coords
          {
            city: city,
            count: count,
            percentage: calculate_percentage(count, total_applicants),
            coordinates: [ lat, lng ]
          }
        end

      cities_data
        .sort_by { |city| -city[:percentage] }
        .reject { |city| city[:coordinates].any?(&:nil?) }
    end
  end

  def date_range_present?
    @start_date.present? && @end_date.present?
  end

  def calculate_trend(current_value, previous_value)
    return 0 if previous_value.zero?
    ((current_value - previous_value) / previous_value.to_f * 100).round(2)
  end

  def previous_period_start_date
    # Get the date of the first candidate record or use a very old date if no records exist
    Candidate.minimum(:created_at)&.beginning_of_day || 10.years.ago.beginning_of_day
  end

  def previous_period_end_date
    (@start_date - 1.day).end_of_day
  end

  def previous_total_applicants
    @previous_total_applicants ||= Candidate
      .where(created_at: previous_period_start_date..previous_period_end_date)
      .count
  end

  def get_attachment_counts(scope)
    scope
      .joins(<<-SQL.strip_heredoc)
        LEFT JOIN active_storage_attachments resume_attach
          ON resume_attach.record_id = candidates.id
          AND resume_attach.record_type = 'Candidate'
          AND resume_attach.name = 'resume'
        LEFT JOIN active_storage_attachments video_attach
          ON video_attach.record_id = candidates.id
          AND video_attach.record_type = 'Candidate'
          AND video_attach.name = 'intro_video'
        LEFT JOIN active_storage_attachments photo_attach
          ON photo_attach.record_id = candidates.id
          AND photo_attach.record_type = 'Candidate'
          AND photo_attach.name = 'photo'
      SQL
      .group("candidates.id")
      .select(<<-SQL.strip_heredoc)
        candidates.*,
        COUNT(DISTINCT resume_attach.id) as has_resume,
        COUNT(DISTINCT video_attach.id) as has_video,
        COUNT(DISTINCT photo_attach.id) as has_photo,
        CASE
          WHEN COUNT(DISTINCT resume_attach.id) > 0
          AND COUNT(DISTINCT video_attach.id) > 0
          AND COUNT(DISTINCT photo_attach.id) > 0
          THEN 1
          ELSE 0
        END as is_complete
      SQL
  end
end
