require "./spec_helper"

describe Transform do
  test "creation" do
    t = Transform.new(1, 2, 3, 4, 5, 6)
    assert t.a == 1
    assert t.b == 2
    assert t.c == 3
    assert t.d == 4
    assert t.tx == 5
    assert t.ty == 6

    # TODO t = Transform.new(b: 4, ty: 2)
    t = Transform.new(1, 4, 0, 1, 0, 2)
    assert t.a == 1
    assert t.b == 4
    assert t.c == 0
    assert t.d == 1
    assert t.tx == 0
    assert t.ty == 2
  end

  test "identity" do
    t = Transform::IDENTITY
    assert t.a == 1
    assert t.b == 0
    assert t.c == 0
    assert t.d == 1
    assert t.tx == 0
    assert t.ty == 0
  end
end
