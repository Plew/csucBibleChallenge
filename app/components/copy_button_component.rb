class CopyButtonComponent < ViewComponent::Base
  def initialize(text:)
    @text = text
  end

  private

  attr_reader :text
end 