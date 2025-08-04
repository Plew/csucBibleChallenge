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
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end