require "./spec_helper"

describe Vect do
  test "creation and access" do
    v = CP::Vect.new(-123.4, 1.7)
    assert v.x == -123.4
    assert v.y == 1.7

    v = CP.v(3, 5)
    assert v.x == 3
    assert v.y == 5

    v = CP.vzero
    assert v.x == 0.0
    assert v.y == 0
  end

  test "math" do
    v = v(111, 222)
    assert v + v(1, 2) == v(112, 224)
    assert v - v(2, 3) == v(109, 219)
    vm = v * 3
    assert vm.x.close? 333
    assert vm.y.close? 666
  end
end
