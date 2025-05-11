# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

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
