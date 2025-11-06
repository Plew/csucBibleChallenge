namespace :fake_munich do
  desc "Generate fake Munich challenge data (deletes and recreates challenge, groups, users, readings, enrollments, and user_readings)"
  task generate: :environment do
    require Rails.root.join("lib/fake_munich")
    FakeMunich.generate!
  end
end
