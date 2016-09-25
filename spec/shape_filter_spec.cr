require "./spec_helper"

describe ShapeFilter do
  test "creation" do
    f = ShapeFilter.new
    assert f.group == 0
    assert f.categories == 0xffffffff
    assert f.mask == 0xffffffff

    f = ShapeFilter.new(1, 2, 3)
    assert f.group == 1
    assert f.categories == 2
    assert f.mask == 3
  end

  test "constants" do
    assert ShapeFilter::ALL_CATEGORIES == 0xffffffff
    assert ShapeFilter::ALL == ShapeFilter.new(0, 0xffffffff, 0xffffffff)
    assert ShapeFilter::NONE == ShapeFilter.new(0, 0, 0)
  end

  test "comparison" do
    f1 = ShapeFilter.new(1, 2, 3)
    f2 = ShapeFilter.new(1, 2, 3)
    f3 = ShapeFilter.new(2, 3, 4)
    assert f1 == f2
    assert f1 != f3
  end
end
