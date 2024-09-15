class CheckInsController < ApplicationController
  def create
    toggle!
    @shown_date = current_date_string
  end

  def toggle!
    check_in = CheckIn.find_by(user: current_user, recorded_on: current_date)

    if check_in
      check_in.destroy
      @checked = false
    else
      CheckIn.create(user: current_user, recorded_on: current_date)
      @checked = true
    end
  end
end