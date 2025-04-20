# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing candidates
puts "Clearing existing candidates..."
Candidate.destroy_all

# Helper method to attach files based on configuration
def attach_files(candidate, with_video: false, use_captured_resume: false)
  if use_captured_resume
    candidate.resume_image.attach(
      io: File.open(Rails.root.join('public', 'scenery.jpeg')),
      filename: 'resume_image.jpeg',
      content_type: 'image/jpeg'
    )
  else
    candidate.resume.attach(
      io: File.open(Rails.root.join('public', 'hello.pdf')),
      filename: 'resume.pdf',
      content_type: 'application/pdf'
    )
  end

  candidate.photo.attach(
    io: File.open(Rails.root.join('public', 'scenery.jpeg')),
    filename: 'photo.jpeg',
    content_type: 'image/jpeg'
  )

  if with_video
    candidate.intro_video.attach(
      io: File.open(Rails.root.join('public', 'Animation.mp4')),
      filename: 'intro.mp4',
      content_type: 'video/mp4'
    )
  end
end

puts "Creating candidates..."

# Base data for generating random candidates
first_names = %w[John Jane Michael Sarah Robert Emma David Lisa Kevin Mary Peter Susan James Linda]
last_names = %w[Smith Johnson Williams Brown Jones Garcia Miller Davis Wilson Anderson Taylor Thomas]
cities = [
  [ "New York", "NY" ], [ "Los Angeles", "CA" ], [ "Chicago", "IL" ], [ "Houston", "TX" ],
  [ "Phoenix", "AZ" ], [ "Philadelphia", "PA" ], [ "San Antonio", "TX" ], [ "San Diego", "CA" ]
]
institutes = [ "State University", "Tech Institute", "Business School", "City College", "National University" ]

# Define valid options for expected salary and career phase
salary_ranges = [ '40k - 80k', '80k - 120k', '120k - 180k', '180k - 250k', '250k+' ]
career_phases = [
  'Entry-Level Professional',
  'Mid-Level Professional',
  'Senior-Level Professional',
  'Career Change',
  'Back to Work',
  'Retired',
  'Specially Abled'
]

# Create 20 candidates
20.times do |i|
  dob = rand(Date.new(1970, 1, 1)..Date.new(2000, 12, 31))
  city_data = cities.sample
  is_employed = [ true, false ].sample

  candidate_data = {
    first_name: first_names.sample,
    last_name: last_names.sample,
    email: "candidate#{i+1}@example.com",
    contact_number: "+1#{rand(1000000000..9999999999)}",
    dob: dob,
    education: Candidate.educations.keys.sample,
    experience: Candidate.experiences.keys.sample,
    expected_salary: salary_ranges.sample,
    career_phase: career_phases.sample,
    function: Candidate.functions.keys.sample,
    institute: institutes.sample,
    address: "#{rand(100..999)} #{%w[Main Oak Maple Pine].sample} #{%w[Street Avenue Boulevard].sample}",
    city: city_data[0],
    state: city_data[1],
    industries: Candidate::INDUSTRIES.sample(rand(1..3)),
    currently_employed: is_employed,
    current_employer: is_employed ? "Company #{rand(1..100)}" : nil,
    current_salary: is_employed ? rand(25000..120000).to_s : nil,
    additional_notes: "Generated candidate #{i+1}"
  }

  candidate = Candidate.new(candidate_data)

  # Determine if this candidate should have captured resume (5 candidates)
  use_captured_resume = i < 5

  # Determine if this candidate should have video (10 candidates)
  with_video = i < 10

  attach_files(candidate, with_video: with_video, use_captured_resume: use_captured_resume)

  if candidate.save
    puts "Created candidate: #{candidate.first_name} #{candidate.last_name}"
  else
    puts "Failed to create candidate: #{candidate.errors.full_messages}"
  end
end

puts "Seed completed! Created #{Candidate.count} candidates."
