module ApplicationHelper
  def flash_class(level)
    case level
    when "notice" then "alert-info"
    when "success" then "alert-success"
    when "error" then "alert-error"
    when "alert" then "alert-warning"
    end
  end

  def current_challenge_for_navbar
    return unless logged_in?
    current_user.challenges.first
  end
end
