class GroupMessagesController < ApplicationController
  before_action :require_login
  before_action :set_group
  before_action :ensure_group_member

  def index
    @messages = @group.group_messages
                      .includes(user: [:avatar_attachment, :avatar_blob])
                      .order(:created_at)
                      .limit(50)
    
    render turbo_stream: turbo_stream.replace("chat-messages", partial: "group_messages/messages", locals: { messages: @messages, current_user: current_user })
  end

  def create
    @message = @group.group_messages.build(message_params.merge(user: current_user))
    
    if @message.save
      @messages = @group.group_messages
                        .includes(user: [:avatar_attachment, :avatar_blob])
                        .order(:created_at)
                        .limit(50)
      
      render turbo_stream: [
        turbo_stream.replace("chat-messages", partial: "group_messages/messages", locals: { messages: @messages, current_user: current_user }),
        turbo_stream.replace("new-message-form", partial: "group_messages/form", locals: { group: @group, message: GroupMessage.new })
      ]
    else
      render turbo_stream: turbo_stream.replace("new-message-form", partial: "group_messages/form", locals: { group: @group, message: @message })
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def ensure_group_member
    enrollment = current_user.user_group_enrollments.find_by(group: @group)
    unless enrollment
      redirect_to groups_path, alert: 'You must be a member of this group to access chat.'
    end
  end

  def message_params
    params.require(:group_message).permit(:content)
  end
end