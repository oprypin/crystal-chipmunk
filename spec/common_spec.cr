require "./spec_helper"

test "moment helpers" do
  m = CP::Circle.moment(1, 2, 3, v(1, 2))
  assert m.close? 11.5

  m = CP::Segment.moment(1, v(-10, 0), v(10, 0), 1)
  assert m.close? 40.6666666666

  m = CP::Poly.moment(1, [v(0, 0), v(10, 10), v(10, 0)], v(1, 2), 3)
  assert m.close? 98.3333333333

  m = CP::Box.moment(1, 2, 3)
  assert m.close? 1.08333333333
end

test "area helpers" do
  a = CP::Circle.area(1, 2)
  assert a.close? 9.4247779607

  a = CP::Segment.area(v(-10, 0), v(10, 0), 3)
  assert a.close? 148.27433388

  a = CP::Poly.area([v(0, 0), v(10, 10), v(10, 0)], 3)
  assert a.close? 80.700740753
end
