class VerseLikesController < ApplicationController
  before_action :require_login
  before_action :set_reading_and_verse

  def toggle
    existing_like = VerseLike.find_by(
      user: current_user,
      reading: @reading,
      verse_number: @verse_number
    )

    if existing_like
      existing_like.destroy
      @liked = false
    else
      VerseLike.create!(
        user: current_user,
        reading: @reading,
        verse_number: @verse_number
      )
      @liked = true
      CheckBadgesJob.perform_later(current_user.id, @reading.challenge_id)
    end

    @like_count = VerseLike.for_verse(@reading.id, @verse_number).count
    @likers = VerseLike.for_verse(@reading.id, @verse_number)
                       .includes(user: [ :avatar_attachment, :avatar_blob ])
                       .map(&:user)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "verse-like-#{@reading.id}-#{@verse_number}",
            partial: "verse_likes/button",
            locals: { reading: @reading, verse_number: @verse_number, liked: @liked, like_count: @like_count }
          ),
          turbo_stream.replace(
            "verse-likers-#{@reading.id}-#{@verse_number}",
            partial: "verse_likes/likers",
            locals: { reading_id: @reading.id, verse_number: @verse_number, likers: @likers }
          )
        ]
      end
      format.html { redirect_back(fallback_location: reading_path) }
    end
  end

  private

  def set_reading_and_verse
    @reading = Reading.find(params[:reading_id])
    @verse_number = params[:verse_number].to_i
  end
end
