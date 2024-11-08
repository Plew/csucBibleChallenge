module ApplicationHelper
  def flash_class(level)
    case level
    when "notice" then "bg-blue-100 text-blue-700"
    when "success" then "bg-green-100 text-green-700"
    when "error" then "bg-red-100 text-red-700"
    when "alert" then "bg-yellow-100 text-yellow-700"
    end
  end
end
