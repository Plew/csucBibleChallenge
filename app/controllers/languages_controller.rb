class LanguagesController < ApplicationController
  def update
    locale = params[:locale]
    
    if I18n.available_locales.map(&:to_s).include?(locale)
      cookies[:locale] = { value: locale, expires: 1.year.from_now }
      I18n.locale = locale
    end
    
    redirect_back(fallback_location: root_path)
  end
end