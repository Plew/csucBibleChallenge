class PieDataFromGroupDay
  def initialize(group, day)
    @group = group
    @day = day
  end

  def pie_chart_data
    pie_chart_rows.map do |data|
      {
        name: data[:name].present? ? data[:name] : 'Anonymous', 
        check_in: data[:check_in]
      }
    end
  end

  private

  def pie_chart_rows
    Group.find_by_sql([
      "SELECT 
        u.name AS name,
        c.recorded_on AS recorded_on,
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
end
