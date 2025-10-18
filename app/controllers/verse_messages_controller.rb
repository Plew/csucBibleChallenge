class VerseMessagesController < ApplicationController
  before_action :require_login
  before_action :set_verse
  before_action :ensure_reading_completed

  def index
    @messages = @verse.verse_messages
                      .includes(user: [:avatar_attachment, :avatar_blob])
                      .order(:created_at)
                      .limit(50)

    render turbo_stream: turbo_stream.replace("verse-chat-messages-#{@verse.id}", partial: "verse_messages/messages", locals: { messages: @messages, current_user: current_user })
  end

  def create
    @message = @verse.verse_messages.build(message_params.merge(user: current_user))

    if @message.save
      @messages = @verse.verse_messages
                        .includes(user: [:avatar_attachment, :avatar_blob])
                        .order(:created_at)
                        .limit(50)

      render turbo_stream: [
        turbo_stream.replace("verse-chat-messages-#{@verse.id}", partial: "verse_messages/messages", locals: { messages: @messages, current_user: current_user, verse: @verse }),
        turbo_stream.replace("verse-new-message-form-#{@verse.id}", partial: "verse_messages/form", locals: { verse: @verse, message: VerseMessage.new })
      ]
    else
      render turbo_stream: turbo_stream.replace("verse-new-message-form-#{@verse.id}", partial: "verse_messages/form", locals: { verse: @verse, message: @message })
    end
  end

  private

  def set_verse
    @verse = Verse.find(params[:verse_id])
  end

  def ensure_reading_completed
    # Find the reading that contains this verse
    reading = current_user.challenges.first&.readings&.find_by(
      book_number: @verse.book_number,
      chapter_number: @verse.chapter_number
    )

    unless reading && current_user.user_readings.exists?(reading_id: reading.id)
      redirect_to reading_path, alert: 'You must complete the reading before participating in verse discussions.'
    end
  end

  def message_params
    params.require(:verse_message).permit(:content)
  end
end
