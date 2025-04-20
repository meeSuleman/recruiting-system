class Candidate < ApplicationRecord
  has_one_attached :resume
  has_one_attached :photo
  has_one_attached :intro_video
  has_one_attached :resume_image

  enum :experience, {
    "Fresh" => 0,
    "1-3 Years" => 1,
    "3-5 Years" => 2,
    "5-8 Years" => 3,
    "8-10 Years" => 4,
    "10-15 Years" => 5,
    "15-20 Years" => 6,
    "20+ Years" => 7
  }

  enum :function, {
    "marketing" => 0,
    "sales" => 1,
    "human_resources" => 2,
    "finance_and_accounting" => 3,
    "procurement_and_purchasing" => 4,
    "supply_chain" => 5,
    "logistics_and_warehouse" => 6,
    "it" => 7,
    "administration" => 8,
    "operations_management" => 9,
    "customer_service_and_support" => 10,
    "business_development" => 11,
    "legal_and_compliance" => 12,
    "product_management" => 13,
    "project_management" => 14,
    "research_and_development" => 15,
    "quality_assurance" => 16,
    "engineering" => 17,
    "design_and_creative" => 18,
    "consulting" => 19,
    "public_relations_and_communications" => 20,
    "demand_planning" => 21,
    "health_safety_and_environment" => 22,
    "corporate_social_responsibility_and_sustainability" => 23,
    "consumer_insight" => 24,
    "other_function" => 25
  }

  enum :education, {
    "matriculation_o_levels" => 0,
    "intermediate_a_levels" => 1,
    "diploma_certification" => 2,
    "bachelors_degree" => 3,
    "masters_degree" => 4,
    "mphil_ms" => 5,
    "phd" => 6
  }

  INDUSTRIES = [
    "fast_moving_consumer_goods",
    "information_technology",
    "healthcare_and_pharmaceuticals",
    "banking_and_financial_services",
    "retail_and_electronic_commerce",
    "manufacturing_and_production",
    "telecommunications",
    "education_and_training",
    "media_and_entertainment",
    "real_estate_and_construction",
    "automotive",
    "energy_and_utilities",
    "logistics_and_transportation",
    "hospitality_and_tourism",
    "nonprofit_and_nongovernmental_organizations",
    "textile",
    "aviation",
    "financial_technology",
    "microfinance_and_electronic_banking",
    "agriculture",
    "energy_and_power_sector",
    "other"
  ].freeze

  validates :first_name, :last_name, :email, :contact_number, :dob, :education, :experience, :career_phase, :institute, :address, :industries, :city, :state, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { message: "has already been used to submit an application" }
  validates :current_salary, presence: true, if: :currently_employed?
  validates :current_employer, presence: true, if: :currently_employed?
  validates :function, :expected_salary, presence: true, if: :fresh_experience?
  # Updated attachment validations
  validates :photo, attached: true
  validate :validate_resume_attachment
  validate :validate_industries

  before_validation :normalize_email, if: :email_changed?

  after_create_commit :send_confirmation_email

  geocoded_by :city
  after_validation :geocode, if: ->(obj) { obj.city_changed? }

  # Add these attributes to store coordinates
  def coordinates
    [ latitude, longitude ] if latitude.present? && longitude.present?
  end

  # Define which attributes can be searched
  def self.ransackable_attributes(auth_object = nil)
    %w[
      first_name last_name email contact_number education
      institute current_employer address city experience
      career_phase created_at
    ]
  end

  # Define which associations can be searched
  def self.ransackable_associations(auth_object = nil)
    []
  end

  # Custom sort for experience enum
  ransacker :experience_label do
    Arel.sql(<<-SQL.squish)
      CASE experience
        WHEN 0 THEN 'Fresh'
        WHEN 1 THEN '1-3 Years'
        WHEN 2 THEN '3-5 Years'
        WHEN 3 THEN '5-8 Years'
        WHEN 4 THEN '8-10 Years'
        WHEN 5 THEN '10-15 Years'
        WHEN 6 THEN '15-20 Years'
        WHEN 7 THEN '20+ Years'
      END
    SQL
  end

  ransacker :education_text do
    Arel.sql(<<-SQL.squish)
      WHEN 0 THEN 'matriculation_o_levels'
      WHEN 1 THEN 'intermediate_a_levels'
      WHEN 2 THEN 'diploma_certification'
      WHEN 3 THEN 'bachelors_degree'
      WHEN 4 THEN 'masters_degree'
      WHEN 5 THEN 'mphil_ms'
      WHEN 6 THEN 'phd'
    END
    SQL
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def intro_video_attached?
    intro_video.attached?
  end

  # Helper method to get human readable industries
  def industry_names
    industries.map { |i| i.titleize }
  end

  def validate_industries
    return if industries.blank?

    industries.each do |industry|
      unless INDUSTRIES.include?(industry)
        errors.add(:industries, "#{industry} is not a valid industry")
      end
    end
  end

  def fresh_experience?
    experience == "Fresh"
  end

  def validate_resume_attachment
    resume_attached = resume.attached?
    resume_image_attached = resume_image.attached?

    if resume_attached && resume_image_attached
      errors.add(:base, "Cannot attach both resume and captured resume. Please provide only one.")
    elsif !resume_attached && !resume_image_attached
      errors.add(:base, "Either resume or captured resume must be attached.")
    end
  end

  def send_confirmation_email
    Rails.logger.info "Starting to send confirmation email to #{email}"
    begin
      CandidateMailer.with(candidate: self).application_confirmation.deliver_later
    rescue => e
      Rails.logger.error "Failed to send confirmation email: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
