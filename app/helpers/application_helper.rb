module ApplicationHelper
  def flash_class(key)
    base_classes = "px-4 py-3 mx-4 my-2 rounded relative text-center"
    
    case key.to_sym
    when :notice, :success
      "#{base_classes} bg-green-100 text-green-700 border border-green-400"
    when :error, :alert
      "#{base_classes} bg-red-100 text-red-700 border border-red-400"
    else
      "#{base_classes} bg-blue-100 text-blue-700 border border-blue-400"
    end
  end
end
