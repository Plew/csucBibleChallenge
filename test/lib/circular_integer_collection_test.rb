require "test_helper"
require_relative "../../app/lib/circular_integer_collection"

class CircularIntegerCollectionTest < ActiveSupport::TestCase
  test "initializes with valid arguments" do
    assert_nothing_raised do
      CircularIntegerCollection.new([ 1, 2, 3 ], 2)
    end
  end

  test "raises ArgumentError when current integer is not in the collection" do
    assert_raises(ArgumentError, "Current integer not found in the collection") do
      CircularIntegerCollection.new([ 1, 2, 3 ], 4)
    end
  end

  test "removes duplicate integers from the collection" do
    collection = CircularIntegerCollection.new([ 1, 2, 2, 3, 3 ], 2)
    assert_equal [ 1, 2, 3 ], collection.instance_variable_get(:@integers)
  end

  test "returns the next integer in the collection" do
    collection = CircularIntegerCollection.new([ 1, 2, 3 ], 2)
    assert_equal 3, collection.next
  end

  test "wraps around to the first integer when at the end" do
    collection = CircularIntegerCollection.new([ 1, 2, 3 ], 3)
    assert_equal 1, collection.next
  end

  test "returns nil for next when collection has one element" do
    collection = CircularIntegerCollection.new([ 1 ], 1)
    assert_nil collection.next
  end

  test "returns the previous integer in the collection" do
    collection = CircularIntegerCollection.new([ 1, 2, 3 ], 2)
    assert_equal 1, collection.previous
  end

  test "wraps around to the last integer when at the beginning" do
    collection = CircularIntegerCollection.new([ 1, 2, 3 ], 1)
    assert_equal 3, collection.previous
  end

  test "returns nil for previous when collection has one element" do
    collection = CircularIntegerCollection.new([ 1 ], 1)
    assert_nil collection.previous
  end
end
