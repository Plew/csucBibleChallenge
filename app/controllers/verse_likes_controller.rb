class VerseLikesController < ApplicationController
  before_action :require_login
  before_action :set_reading_and_verse

  def create
    @like = @reading.verse_likes.find_or_initialize_by(
      user: current_user,
      verse_number: @verse_number
    )

    if @like.new_record? && @like.save
      render json: {
        liked: true,
        like_count: @reading.verse_likes.where(verse_number: @verse_number).count
      }
    elsif @like.persisted?
      # Already liked
      render json: {
        liked: true,
        like_count: @reading.verse_likes.where(verse_number: @verse_number).count
      }
    else
      render json: { error: "Failed to like verse" }, status: :unprocessable_entity
    end
  end

  def destroy
    @like = @reading.verse_likes.find_by(
      user: current_user,
      verse_number: @verse_number
    )

    if @like
      @like.destroy
      render json: {
        liked: false,
        like_count: @reading.verse_likes.where(verse_number: @verse_number).count
      }
    else
      render json: {
        liked: false,
        like_count: @reading.verse_likes.where(verse_number: @verse_number).count
      }
    end
  end

  private

  def set_reading_and_verse
    @reading = Reading.find(params[:reading_id])
    @verse_number = params[:verse_number].to_i
  end
end
