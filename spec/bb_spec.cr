require "./spec_helper"

describe BB do
  test "creation" do
    bb_empty = BB.new()

    assert bb_empty.left == 0
    assert bb_empty.bottom == 0
    assert bb_empty.right == 0
    assert bb_empty.top  == 0

    bb_defined = BB.new(-10, -5, 15, 20)

    assert bb_defined.left == -10
    assert bb_defined.bottom == -5
    assert bb_defined.right == 15
    assert bb_defined.top == 20

    bb_circle = BB.new_for_circle(v(3, 3), 3)
    assert bb_circle.left == 0
    assert bb_circle.bottom == 0
    assert bb_circle.right == 6
    assert bb_circle.top == 6
  end

  test "merge" do
    bb1 = BB.new(0, 0, 10, 10)
    bb2 = BB.new(2, 0, 10, 10)
    bb3 = BB.new(10, 10, 15, 15)

    assert bb1.merge(bb2) == BB.new(0, 0, 10, 10)
    assert bb2.merge(bb3).merge(bb1) == BB.new(0, 0, 15, 15)
  end

  test "methods" do
    bb1 = BB.new(0, 0, 10, 10)
    bb2 = BB.new(10, 10, 20, 20)
    bb3 = BB.new(4, 4, 5, 5)
    bb4 = BB.new(2, 0, 10, 10)

    v1 = v(1, 1)
    v2 = v(100, 3)
    assert bb1.intersects?(bb2)
    assert !bb3.intersects?(bb2)

    assert bb1.intersects_segment?(v1, v2)
    assert !bb3.intersects_segment?(v1, v2)

    assert bb1.contains?(bb3)
    assert !bb1.contains?(bb2)

    assert bb1.contains?(v1)
    assert !bb1.contains?(v2)

    assert bb1.expand(v1) == bb1
    assert bb1.expand(-v2) == BB.new(-100, -3, 10, 10)

    assert bb1.center == v(5, 5)
    assert bb1.area() == 100

    assert bb1.merge(bb2).area() == 400

    assert bb2.segment_query(v1, v2) == Float64::INFINITY
    assert bb1.segment_query(v(-1, 1), v(99, 1)) == 0.01

    assert bb1.clamp_vect(v2) == v(10, 3)
  end
end
