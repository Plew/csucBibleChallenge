module AuthenticationHelpers
  def login_as(user)
    post user_session_path, params: {
      session: {
        email: user.email,
        password: 'password123' # matching the factory password
      }
    }
  end

  def login_via_session(user)
    # Direct session manipulation for request specs
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  # Convenience method to include realistic context and login as primary user
  # Usage:
  #   before { setup_and_login_with_realistic_data }
  #
  # Or to login as a different user:
  #   before { setup_and_login_with_realistic_data(active_user) }
  def setup_and_login_with_realistic_data(user = nil)
    # The realistic challenge context must be included in the spec
    # This method just handles the login portion
    user_to_login = user || primary_user
    login_as(user_to_login)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request

  # Set default host to localhost for request specs to avoid Rails 8.1 host authorization blocking
  config.before(:each, type: :request) do
    host! "localhost"
  end
end
