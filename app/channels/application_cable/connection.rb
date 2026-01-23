module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Access the session stored in the encrypted cookie
      if (user_id = session_from_cookie["user_id"])
        User.find_by(id: user_id)
      else
        reject_unauthorized_connection
      end
    end

    def session_from_cookie
      cookies.encrypted[Rails.application.config.session_options[:key]] || {}
    end
  end
end
