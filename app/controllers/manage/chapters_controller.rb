class Manage::ChaptersController < Manage::BaseController
  def index
    @readings = @challenge.readings.order(:scheduled_date, :book_number, :chapter_number)
  end
end
