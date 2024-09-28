class PieDataFromGroupDay
  def initialize(group, day)
    @group = group
    @day = day
  end

  def pie_chart_data
    Group.find_by_sql([
      "SELECT 
        u.name AS user_name,
        CASE 
          WHEN c.id IS NOT NULL THEN 1
          ELSE 0
        END AS check_in
      FROM users u
      JOIN group_memberships gm ON u.id = gm.user_id
      LEFT JOIN check_ins c ON u.id = c.user_id AND c.recorded_on = ?
      WHERE gm.group_id = ?
      ORDER BY check_in DESC, u.name",
      @day, @group.id
    ])
  end

  def pie_chart_data_to_json
    pie_chart_data.map do |data|
      {
        name: data[:user_name],
        value: data[:check_in]
      }
    end
  end

end
