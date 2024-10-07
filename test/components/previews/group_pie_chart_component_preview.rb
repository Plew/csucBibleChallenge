class GroupPieChartComponentPreview < ViewComponent::Preview
  def solo
    render(GroupPieChartComponent.new(one_user))
  end

  def many
    render(GroupPieChartComponent.new(many_users))
  end

  # def default
  #   group = Group.new(name: "Sample Group")
  #   user1 = User.new(name: "Alice")
  #   user2 = User.new(name: "Bob")
  #   user1.stub(:check_ins) { [CheckIn.new] * 5 }
  #   user2.stub(:check_ins) { [CheckIn.new] * 3 }
  #   group.stub(:users) { [user1, user2] }

  #   render(GroupPieChartComponent.new(group: group))
  # end

  # def empty_group
  #   group = Group.new(name: "Empty Group")
  #   group.stub(:users) { [] }

  #   render(GroupPieChartComponent.new(group: group))
  # end

  private

  def many_users
    7.times.map do |i|
      [ "User #{i}", [0, 1].sample  ]
    end
  end

  def one_user
    [ 
      [ "Alice", 1 ],
    ]
  end

  def default
    group = Group.new(name: "Sample Group")
    user1 = User.new(name: "Alice")
    user2 = User.new(name: "Bob")
    day = Date.today
    
    allow(user1).to receive_message_chain(:check_ins, :exists?).and_return(true)
    allow(user2).to receive_message_chain(:check_ins, :exists?).and_return(false)
    allow(group).to receive(:users).and_return([user1, user2])

    render(GroupPieChartComponent.new(group: group, day: day))
  end

  def empty_group
    group = Group.new(name: "Empty Group")
    day = Date.today
    allow(group).to receive(:users).and_return([])

    render(GroupPieChartComponent.new(group: group, day: day))
  end
end