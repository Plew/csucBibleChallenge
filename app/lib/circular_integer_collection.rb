# frozen_string_literal: true

class CircularIntegerCollection
  def initialize(integers, current)
    @integers = integers.uniq
    @current = current
    @current_index = @integers.index(current)

    raise ArgumentError, "Current integer not found in the collection" if @current_index.nil?
  end

  def next
    return nil if @integers.size <= 1
    next_index = (@current_index + 1) % @integers.size
    @integers[next_index]
  end

  def previous
    return nil if @integers.size <= 1
    previous_index = (@current_index - 1) % @integers.size
    @integers[previous_index]
  end
end
