namespace :fake_munich_future do
  desc 'Generate fake Munich challenge data starting one week in the future (deletes and recreates challenge, groups, users, readings, and enrollments)'
  task generate: :environment do
    require Rails.root.join('lib/fake_munich_future')
    FakeMunichFuture.generate!
  end
end
