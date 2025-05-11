class HomeController < ApplicationController
  # GET /
  def index
    # In a real application, you would fetch the user's current challenge(s)
    # and their reading for today.
    # For now, we can use placeholders or assume no reading to show the basic page structure.

    # Example: Fetch current user's readings for today
    # if current_user # Assuming a current_user helper method
    #   @today_readings = current_user.readings.where(scheduled_date: Date.today)
    # else
    #   # Handle user not logged in - perhaps redirect to login or show a generic page
    #   # For now, we might just show the "no readings" message if no current_user
    #   @today_readings = []
    # end

    # Placeholder data for demonstration
    @today_readings = [
      # OpenStruct.new(challenge_name: "Old Testament Challenge", reading_title: "Genesis Chapter 1", reference: "Genesis 1", verses: ["In the beginning God created the heavens and the earth.", "Now the earth was formless and empty, darkness was over the surface of the deep, and the Spirit of God was hovering over the waters."], completed: false),
      # OpenStruct.new(challenge_name: "New Testament Journey", reading_title: "Matthew Chapter 1", reference: "Matthew 1", verses: ["The book of the genealogy of Jesus Christ, the son of David, the son of Abraham.", "Abraham was the father of Isaac, and Isaac the father of Jacob, and Jacob the father of Judah and his brothers."], completed: true)
    ]

    # Simulate a case where there are no readings
    # @today_readings = []
  end
end 