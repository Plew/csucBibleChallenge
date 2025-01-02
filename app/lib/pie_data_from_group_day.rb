class PieDataFromGroupDay
  def initialize(group, day)
    @group = group
    @day = day
  end

  def pie_chart_data
    pie_chart_rows.map do |data|
      {
        name: data[:name],
        checked_in_value: data[:checked_in_value]
      }
    end
  end

  private

  def pie_chart_rows
    Group.find_by_sql([
      "SELECT 
        COALESCE(NULLIF(u.name, ''), 'Anonymous') AS name,
        c.recorded_on AS recorded_on,
        CASE 
          WHEN c.id IS NOT NULL THEN 1
          ELSE 0
        END AS checked_in_value
      FROM users u
      JOIN group_memberships gm ON u.id = gm.user_id
      LEFT JOIN check_ins c ON u.id = c.user_id AND c.recorded_on = ?
      WHERE gm.group_id = ?
      ORDER BY checked_in_value DESC, u.name",
      @day, @group.id
    ])
  end
end
