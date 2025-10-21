class VerseMessagesController < ApplicationController
  before_action :require_login
  before_action :set_reading_and_verse
  before_action :ensure_reading_completed

  def index
    @messages = VerseMessage.for_verse(@reading.id, @verse_number)
                            .includes(user: [:avatar_attachment, :avatar_blob])
                            .order(:created_at)
                            .limit(50)

    render turbo_stream: turbo_stream.replace("verse-chat-messages-#{@reading.id}-#{@verse_number}", partial: "verse_messages/messages", locals: { messages: @messages, current_user: current_user })
  end

  def create
    @message = @reading.verse_messages.build(
      message_params.merge(
        user: current_user,
        verse_number: @verse_number
      )
    )

    if @message.save
      @messages = VerseMessage.for_verse(@reading.id, @verse_number)
                              .includes(user: [:avatar_attachment, :avatar_blob])
                              .order(:created_at)
                              .limit(50)

      render turbo_stream: [
        turbo_stream.replace("verse-chat-messages-#{@reading.id}-#{@verse_number}", partial: "verse_messages/messages", locals: { messages: @messages, current_user: current_user, reading: @reading, verse_number: @verse_number }),
        turbo_stream.replace("verse-new-message-form-#{@reading.id}-#{@verse_number}", partial: "verse_messages/form", locals: { reading: @reading, verse_number: @verse_number, message: VerseMessage.new })
      ]
    else
      render turbo_stream: turbo_stream.replace("verse-new-message-form-#{@reading.id}-#{@verse_number}", partial: "verse_messages/form", locals: { reading: @reading, verse_number: @verse_number, message: @message })
    end
  end

  def destroy
    @message = VerseMessage.find(params[:id])

    # Only allow users to delete their own messages
    unless @message.user_id == current_user.id
      head :forbidden
      return
    end

    @message.destroy

    @messages = VerseMessage.for_verse(@reading.id, @verse_number)
                            .includes(user: [:avatar_attachment, :avatar_blob])
                            .order(:created_at)
                            .limit(50)

    render turbo_stream: turbo_stream.replace(
      "verse-chat-messages-#{@reading.id}-#{@verse_number}",
      partial: "verse_messages/messages",
      locals: { messages: @messages, current_user: current_user, reading: @reading, verse_number: @verse_number }
    )
  end

  private

  def set_reading_and_verse
    @reading = Reading.find(params[:reading_id])
    @verse_number = params[:verse_number].to_i
  end

  def ensure_reading_completed
    unless current_user.user_readings.exists?(reading_id: @reading.id)
      redirect_to reading_path, alert: 'You must complete the reading before participating in verse discussions.'
    end
  end

  def message_params
    params.require(:verse_message).permit(:content)
  end
end
