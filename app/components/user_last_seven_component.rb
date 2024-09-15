class UserLastSevenComponent < ViewComponent::Base
  attr_reader :check_ins

  def initialize(check_ins:)
    @check_ins = check_ins.dup
    # false pad the check_ins to 7 days
    @check_ins.fill(false, @check_ins.length...7)
  end


end