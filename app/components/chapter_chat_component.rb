class ChapterChatComponent < ViewComponent::Base
  include ApplicationHelper
  include Turbo::FramesHelper

  def initialize(group:, current_user:, user_group:)
    @group = group
    @current_user = current_user
    @user_group = user_group
  end

  private

  attr_reader :group, :current_user, :user_group

  def messages
    @messages ||= group.group_messages
                      .includes(user: [:avatar_attachment, :avatar_blob])
                      .order(:created_at)
                      .limit(50)
  end

  def can_chat?
    user_group && group == user_group
  end

  def new_message
    @new_message ||= GroupMessage.new
  end
end
