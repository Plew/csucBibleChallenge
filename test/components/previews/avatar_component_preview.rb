# frozen_string_literal: true

class AvatarComponentPreview < ViewComponent::Preview
  # Preview showing all available avatar sizes
  # @label Avatar Sizes
  def sizes
    render_with_template(
      locals: {
        user: User.first || create_sample_user
      }
    )
  end

  # Preview showing avatar with custom HTML options
  # @label Avatar with Custom Classes
  def with_custom_classes
    user = User.first || create_sample_user
    render(AvatarComponent.new(
      user: user,
      size: :large,
      html_options: { class: "rounded-full ring ring-primary ring-offset-2" }
    ))
  end

  # Preview showing avatar for user without uploaded avatar (uses Avatarro)
  # @label Avatar with Avatarro Fallback
  def with_avatarro_fallback
    user = User.first || create_sample_user
    # Temporarily remove avatar to show Avatarro fallback
    render(AvatarComponent.new(
      user: OpenStruct.new(username: user.username, avatar: OpenStruct.new(attached?: false)),
      size: :medium
    ))
  end

  # Preview showing multiple avatars in a grid
  # @label Avatar Grid
  def grid
    render_with_template(
      locals: {
        user: User.first || create_sample_user
      }
    )
  end

  private

  def create_sample_user
    OpenStruct.new(
      username: "sample_user",
      avatar: OpenStruct.new(attached?: false)
    )
  end
end
