class StatsCardHorizontalComponentPreview < ViewComponent::Preview
  def default
    render StatsCardHorizontalComponent.new(
      today_reading: "John 9",
      challenge_members: 53,
      chapters_read: 193,
      chapters_today: 22,
      top_readers: ["Jim", "Sally", "Shirley"]
    )
  end

  def with_longer_names
    render StatsCardHorizontalComponent.new(
      today_reading: "1 Chronicles 15",
      challenge_members: 127,
      chapters_read: 1456,
      chapters_today: 8,
      top_readers: ["Christopher", "Alexandria", "Montgomery"]
    )
  end
end