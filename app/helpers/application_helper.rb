module ApplicationHelper
  def flash_class(level)
    base_classes = "absolute top-0 left-0 right-0 z-50 p-4 text-center w-full"
    case level
    when "notice" then "#{base_classes} bg-blue-100 text-blue-700 mt-8 mx-8"
    when "success" then "#{base_classes} bg-green-100 text-green-700 mt-8 mx-8"
    when "error" then "#{base_classes} bg-red-100 text-red-700 mt-8 mx-8"
    when "alert" then "#{base_classes} bg-yellow-100 text-yellow-700 mt-8 mx-8"
    end
  end
end
