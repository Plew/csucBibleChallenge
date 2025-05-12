# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# To generate fake Munich challenge data for local development, run:
#   rake fake_munich:generate
#
# puts 'Starting KJV Bible import for seeds...'
# ImportKjv.call
# puts 'Finished KJV Bible import.'

puts 'Creating Munich Fall Reading Challenge...'
challenge = Challenge.find_or_create_by!(name: 'Munich Fall Reading Challenge') do |c|
  c.start_date = Date.today
  c.end_date = Date.today + 3.months
  c.timezone = 'Berlin'
end
puts 'Challenge created.'

puts 'Creating groups for Munich Fall Reading Challenge...'
['Sauerkraut', 'Bratwurst', 'Pretzel', 'Schnitzel'].each do |food_name|
  challenge.groups.find_or_create_by!(name: food_name)
  puts "Group '#{food_name}' created."
end
puts 'Finished creating groups.'

puts "Creating readings for '#{challenge.name}'..."
(1..21).each do |chapter_num|
  scheduled_reading_date = challenge.start_date + (chapter_num - 1).days
  reading_title = "John Chapter #{chapter_num}"

  challenge.readings.find_or_create_by!(book_number: 43, chapter_number: chapter_num) do |reading|
    reading.title = reading_title
    reading.scheduled_date = scheduled_reading_date
    # Ensure other necessary attributes for Reading are set if any
  end
  puts "Created reading: #{reading_title} for #{scheduled_reading_date.strftime('%Y-%m-%d')}"
end
puts "Finished creating readings for '#{challenge.name}'."

puts 'Creating sample users and enrolling them in groups...'
german_names = [
  ['Lukas', 'Müller'],
  ['Anna', 'Schmidt'],
  ['Max', 'Schneider'],
  ['Sophie', 'Fischer'],
  ['Leon', 'Weber'],
  ['Mia', 'Meyer'],
  ['Ben', 'Wagner'],
  ['Emma', 'Becker'],
  ['Paul', 'Hoffmann'],
  ['Laura', 'Schäfer']
]
groups = challenge.groups.order(:name).to_a

german_names.each_with_index do |(first, last), idx|
  ascii_first = I18n.transliterate(first.downcase)
  ascii_last = I18n.transliterate(last.downcase)
  email = "#{ascii_first}.#{ascii_last}@example.com"
  user = User.find_or_create_by!(email: email) do |u|
    u.username = "#{ascii_first}#{ascii_last}"
    u.password = 'password123'
  end
  group = groups[idx % groups.size]
  enrollment = UserChallengeEnrollment.find_or_create_by!(user: user, challenge: challenge) do |e|
    e.group = group
  end
  enrollment.update!(group: group) unless enrollment.group == group
  puts "User #{user.username} enrolled in group #{group.name}."
end
puts 'Finished creating sample users and enrollments.'
