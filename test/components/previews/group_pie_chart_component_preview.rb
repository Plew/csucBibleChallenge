class GroupPieChartComponentPreview < ViewComponent::Preview
  def solo
    render(GroupPieChartComponent.new(one_user))
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

  def one_user
    [ 
      { name: "Alice", check_in: [true,false].sample },
    ]
  end
end