require "./spec_helper"

describe Shape do
  test "point_query" do
    b = Body.new(10, 10)
    c = Circle.new(b, 5)
    c.cache_bb()
    info = c.point_query(v(0, 0))
    assert info.shape == c
    assert info.point == v(0, 0)
    assert info.distance == -5
    assert info.gradient == v(0, 1)

    info = c.point_query(v(11, 0))
    assert info.shape == c
    assert info.point == v(5, 0)
    assert info.distance == 6
    assert info.gradient == v(1, 0)
  end

  test "segment_query" do
    s = Space.new()
    b = Body.new(10, 10)
    c = Circle.new(b, 5)
    c.cache_bb()

    info = c.segment_query(v(10, -50), v(10, 50))
    assert !info

    info = c.segment_query(v(10, -50), v(10, 50), 6)
    assert info
    assert info.shape == c

    info = c.segment_query(v(0, -50), v(0, 50))
    assert info
    assert info.shape == c
    assert info.point.x.close? 0
    assert info.point.y.close? -5
    assert info.normal.x.close? 0
    assert info.normal.y.close? -1
    assert info.alpha == 0.45
  end

  test "mass" do
    c = Circle.new(nil, 1)
    assert c.mass == 0
    c.mass = 2
    assert c.mass == 2
  end

  test "density" do
    c = Circle.new(nil, 1)
    assert c.density == 0
    c.density = 2
    assert c.density == 2
  end

  test "moment" do
    c = Circle.new(nil, 5)
    assert c.moment == 0
    c.density = 2
    assert c.moment.close? 1963.4954084936207
    c.density = 0
    c.mass = 2
    assert c.moment.close? 25
  end

  test "area" do
    c = Circle.new(nil, 5)
    assert c.area.close? 78.53981633974483
  end

  test "center_of_gravity" do
    c = Circle.new(nil, 5)
    assert c.center_of_gravity.x == 0
    assert c.center_of_gravity.y == 0
    c = Circle.new(nil, 5, v(10, 5))
    assert c.center_of_gravity.x == 10
    assert c.center_of_gravity.y == 5
  end

  test "no body" do
    c = Circle.new(nil, 1)
    assert c.body == nil
  end

  test "remove body" do
    b = Body.new(1, 1)
    c = Circle.new(b, 1)
    c.body = nil

    assert c.body == nil
    assert b.shapes.empty?
  end

  test "switch body" do
    s = Space.new()
    b1 = s.add Body.new(1, 1)
    b2 = s.add Body.new(1, 1)
    c = s.add Circle.new(b1, 1)

    assert c.body == b1
    assert b1.shapes.includes? c
    assert !(b2.shapes.includes? c)

    s.remove c
    c.body = b2
    s.add c

    assert c.body == b2
    assert !(b1.shapes.includes? c)
    assert b2.shapes.includes? c
  end

  test "sensor" do
    b1 = Body.new(1, 1)
    c = Circle.new(b1, 1)
    assert !c.sensor?
    c.sensor = true
    assert c.sensor?
  end

  test "elasticity" do
    b1 = Body.new(1, 1)
    c = Circle.new(b1, 1)
    assert c.elasticity == 0
    c.elasticity = 1
    assert c.elasticity == 1
  end

  test "friction" do
    b1 = Body.new(1, 1)
    c = Circle.new(b1, 1)
    assert c.friction == 0
    c.friction = 1
    assert c.friction == 1
  end

  test "surface_velocity" do
    b1 = Body.new(1, 1)
    c = Circle.new(b1, 1)
    assert c.surface_velocity == v(0, 0)
    c.surface_velocity = v(1, 2)
    assert c.surface_velocity == v(1, 2)
  end

  test "collision_type" do
    b1 = Body.new(1, 1)
    c = Circle.new(b1, 1)
    assert c.collision_type == 0
    c.collision_type = 1
    assert c.collision_type == 1
  end

  test "filter" do
    b1 = Body.new(1, 1)
    c = Circle.new(b1, 1)
    assert c.filter == ShapeFilter.new(0, 0xffffffff, 0xffffffff)
    c.filter = ShapeFilter.new(1, 0xfffffff2, 0xfffffff3)
    assert c.filter == ShapeFilter.new(1, 0xfffffff2, 0xfffffff3)
  end

  test "space" do
    b1 = Body.new(1, 1)
    c = Circle.new(b1, 1)
    assert c.space == nil
    s = Space.new()
    s.add b1, c
    assert c.space == s

  end

  test "collide" do
    b1 = Body.new(1, 1)
    s1 = Circle.new(b1, 10)

    b2 = Body.new(1, 1)
    b2.position = v(30, 30)
    s2 = Circle.new(b2, 10)

    c = s1.collide(s2)
    assert c.normal == v(1, 0)
    assert c.points.size == 1
    point = c.points[0]
    assert point.point_a == v(10, 0)
    assert point.point_b == v(-10, 0)
    assert point.distance == -20
  end
end

describe Circle do
  test "cache_bb" do
    s = Space.new()
    b = Body.new(10, 10)
    c = Circle.new(b, 5)

    c.cache_bb()

    assert c.bb == BB.new(-5.0, -5.0, 5.0, 5.0)
  end

  test "no body" do
    s = Space.new()
    c = Circle.new(nil, 5)

    bb = c.update(Transform.new(1, 2, 3, 4, 5, 6))
    assert c.bb == bb
    assert c.bb == BB.new(0, 1, 10, 11)
  end

  test "offset" do
    c = Circle.new(nil, 5, v(1, 2))
    assert c.offset == v(1, 2)

    c.offset = v(3, 4)
    assert c.offset == v(3, 4)
  end

  test "radius" do
    c = Circle.new(nil, 5)
    assert c.radius == 5

    c.radius = 3
    assert c.radius == 3
  end
end

describe Segment do
  test "cache_bb" do
    s = Space.new()
    b = Body.new(10, 10)
    c = Segment.new(b, v(2, 2), v(2, 3), 2)

    c.cache_bb()

    assert c.bb == BB.new(0, 0, 4.0, 5.0)
  end

  test "properties" do
    c = Segment.new(nil, v(2, 2), v(2, 3), 4)

    assert c.a == v(2, 2)
    assert c.b == v(2, 3)
    assert c.normal == v(1, 0)
    assert c.radius == 4
  end

  test "unsafe properties" do
    c = Segment.new(nil, v(2, 2), v(2, 3), 4)

    c.set_endpoints(v(3, 4), v(5, 6))
    assert c.a == v(3, 4)
    assert c.b == v(5, 6)

    c.radius = 5
    assert c.radius == 5
  end

  test "set_neighbors" do
    c = Segment.new(nil, v(2, 2), v(2, 3), 1)
    c.set_neighbors(v(2, 2), v(2, 3))
  end

  test "segment-segment collision" do
    s = Space.new()
    b1 = Body.new(10, 10)
    c1 = Segment.new(b1, v(-1, -1), v(1, 1), 1)
    b2 = Body.new(10, 10)
    c2 = Segment.new(b2, v(1, -1), v(-1, 1), 1)
    s.add b1, b2, c1, c2

    h = s.add_collision_handler(CountBeginHandler.new)
    s.step(0.1)

    assert h.hits == 1
  end
end

describe Poly do
  test "creation" do
    c = Poly.new(nil, [v(0, 0), v(10, 10), v(20, 0), v(-10, 10)])

    b = Body.new(1, 2)
    c = Poly.new(b, [v(0, 0), v(10, 10), v(20, 0), v(-10, 10)], Transform::IDENTITY, 6)
  end

  test "get verts" do
    vs = [v(-10, 10), v(0, 0), v(20, 0), v(10, 10)]
    c = Poly.new(nil, vs)

    assert c.to_a == vs

    c = Poly.new(nil, vs, Transform.new(1, 2, 3, 4, 5, 6), 0)

    vs2 = [v(5.0, 6.0), v(25.0, 26.0), v(45.0, 66.0), v(25.0, 46.0)]
    assert c.to_a == vs2
  end

  test "set_verts" do
    vs = [v(-10, 10), v(0, 0), v(20, 0), v(10, 10)]
    c = Poly.new(nil, vs)

    vs2 = [v(-3, 3), v(0, 0), v(3, 0)]
    c.set_verts(vs2)
    assert c.to_a == vs2

    vs3 = [v(-4, 4), v(0, 0), v(4, 0)]
    c.set_verts(vs3, Transform::IDENTITY)
    assert c.to_a == vs3

  end

  test "cache_bb" do
    c = Poly.new(nil, [v(2, 2), v(4, 3), v(3, 5)])
    bb = c.update(Transform::IDENTITY)
    assert bb == c.bb
    assert c.bb == BB.new(2, 2, 4, 5)

    b = Body.new(1, 2)
    c = Poly.new(b, [v(2, 2), v(4, 3), v(3, 5)])
    c.cache_bb()
    assert c.bb == BB.new(2, 2, 4, 5)

    s = Space.new()
    b = Body.new(1, 2)
    c = Poly.new(b, [v(2, 2), v(4, 3), v(3, 5)])
    s.add b, c
    assert c.bb == BB.new(2, 2, 4, 5)
  end

  test "radius" do
    c = Poly.new(nil, [v(2, 2), v(4, 3), v(3, 5)], radius=10)
    assert c.radius == 10

    c.radius = 20
    assert c.radius == 20
  end
end

describe Shape::Box do
  test do
    c = Shape::Box.new(nil, 4, 2, 3)
    assert c.to_a == [v(2, -1), v(2, 1), v(-2, 1), v(-2, -1)]

    c = Shape::Box.new(nil, BB.new(1, 2, 3, 4), 3)
    assert c.to_a == [v(3, 2), v(3, 4), v(1, 4), v(1, 2)]
  end
end


class CountBeginHandler < CollisionHandler
  getter hits = 0

  def begin(arbiter, space)
    @hits += 1
    true
  end
end
