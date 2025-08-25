class StatsCardResponsiveComponentPreview < ViewComponent::Preview
  def default
    render StatsCardResponsiveComponent.new(
      today_reading: "John 9",
      challenge_members: 53,
      chapters_read: 193,
      chapters_today: 22,
      top_readers: ["Jim", "Sally", "Shirley"]
    )
  end
end