require "./spec_helper"

class TestSpace < Space
  def initialize
    super

    @b1 = Body.new(1, 3)
    @b2 = Body.new(10, 100)
    @b1.position = v(10, 0)
    @b2.position = v(20, 0)

    @s1 = Circle.new(b1, 5)
    @s2 = Circle.new(b2, 10)

    add b1, b2, s1, s2
  end

  getter b1, b2, s1, s2
end

describe Space do
  test "properties" do
    s = Space.new()

    assert s.iterations == 10
    s.iterations = 15
    assert s.iterations == 15

    assert s.gravity == v(0, 0)
    s.gravity = v(10, 2)
    assert s.gravity == v(10, 2)
    assert s.gravity.x == 10

    assert s.damping == 1
    s.damping = 3
    assert s.damping == 3

    assert s.idle_speed_threshold == 0
    s.idle_speed_threshold = 4
    assert s.idle_speed_threshold == 4

    assert s.sleep_time_threshold.infinite?
    s.sleep_time_threshold = 5
    assert s.sleep_time_threshold == 5

    assert s.collision_slop.close? 0.1
    s.collision_slop = 6
    assert s.collision_slop == 6

    assert s.collision_bias.close? 0.0017970074436
    s.collision_bias = 0.2
    assert s.collision_bias == 0.2

    assert s.collision_persistence == 3
    s.collision_persistence = 9u32
    assert s.collision_persistence == 9

    assert s.current_time_step == 0
    s.step(0.1)
    assert s.current_time_step == 0.1

    assert s.static_body != nil
    assert s.static_body.type == Body::STATIC
  end

  test "add/remove" do
    s = Space.new()

    assert s.bodies.empty?
    assert s.shapes.empty?

    b = s.add Body.new(1, 2)
    assert s.bodies.to_a == [b]
    assert s.shapes.empty?

    c1 = s.add Circle.new(b, 10)
    assert s.bodies.to_a == [b]
    assert s.shapes.to_a == [c1]

    c2 = s.add Circle.new(b, 15)
    assert s.shapes.size == 2
    assert s.shapes.includes? c1
    assert s.shapes.includes? c2

    s.remove c1
    assert s.shapes.to_a == [c2]

    s.remove c2, b
    assert s.bodies.empty?
    assert s.shapes.empty?

    s.add b, c2
    assert s.bodies.to_a == [b]
    assert s.shapes.to_a == [c2]
  end

  test "add/remove in step" do
    s = Space.new()

    b1 = s.add Body.new(1, 2)
    c1 = s.add Circle.new(b1, 2)

    b2 = s.add Body.new(1, 2)
    c2 = s.add Circle.new(b2, 2)

    b = Body.new(1, 2)
    c = Circle.new(b, 2)

    handler = s.add_collision_handler(CollisionType.new(0), CollisionType.new(0), AddRemoveHandler.new(b, c))

    s.step(0.1)

    assert s.bodies.includes? b
    assert s.shapes.includes? c

    s.step(0.1)

    assert !(s.bodies.includes? b)
    assert !(s.shapes.includes? c)
  end

  test "remove in step" do
    s = TestSpace.new()

    s.add_collision_handler(CollisionType.new(0), CollisionType.new(0), RemoveArbiterHandler.new)

    s.step(0.1)

    assert !(s.bodies.includes? s.s1)
    assert !(s.shapes.includes? s.s2)
  end

  test "point_query_nearest with shape filter" do
    s = Space.new()
    b1 = s.add Body.new(1, 1)
    s1 = s.add Circle.new(b1, 10)

    [
      {c1: 0b00, m1: 0b00, c2: 0b00, m2: 0b00, hit: false},
      {c1: 0b01, m1: 0b01, c2: 0b01, m2: 0b01, hit: true},
      {c1: 0b10, m1: 0b01, c2: 0b01, m2: 0b10, hit: true},
      {c1: 0b01, m1: 0b01, c2: 0b11, m2: 0b11, hit: true},
      {c1: 0b11, m1: 0b00, c2: 0b11, m2: 0b00, hit: false},
      {c1: 0b00, m1: 0b11, c2: 0b00, m2: 0b11, hit: false},
      {c1: 0b01, m1: 0b10, c2: 0b10, m2: 0b00, hit: false},
      {c1: 0b01, m1: 0b10, c2: 0b10, m2: 0b10, hit: false},
      {c1: 0b01, m1: 0b10, c2: 0b10, m2: 0b01, hit: true},
      {c1: 0b01, m1: 0b11, c2: 0b00, m2: 0b10, hit: false},
    ].each do |test|
      f1 = ShapeFilter.new(categories: test[:c1], mask: test[:m1])
      f2 = ShapeFilter.new(categories: test[:c2], mask: test[:m2])
      s1.filter = f1
      hit = s.point_query_nearest(v(0, 0), 0, f2)
      if test[:hit]
        assert hit
      else
        assert hit.nil?
      end
    end
  end

  test "point_query" do
    s = Space.new()
    b1 = s.add Body.new(1, 1)
    b1.position = v(19, 0)
    s1 = s.add Circle.new(b1, 10)

    b2 = s.add Body.new(1, 1)
    b2.position = v(0, 0)
    s2 = s.add Circle.new(b2, 10)
    s1.filter = ShapeFilter.new(categories: 0b10, mask: 0b01)
    hits = s.point_query(v(23, 0), 0, ShapeFilter.new(categories: 0b01, mask: 0b10))

    assert hits.size == 1
    assert hits[0].shape == s1
    assert hits[0].point == v(29, 0)
    assert hits[0].distance == -6
    assert hits[0].gradient == v(1, 0)

    hits = s.point_query(v(30, 0))
    assert hits.empty?

    hits = s.point_query(v(30, 0), 30)
    assert hits.size == 2
    assert hits[0].shape == s2
    assert hits[0].point == v(10, 0)
    assert hits[0].distance == 20
    assert hits[0].gradient == v(1, 0)

    assert hits[1].shape == s1
    assert hits[1].point == v(29, 0)
    assert hits[1].distance == 1
    assert hits[1].gradient == v(1, 0)
  end

  test "point_query with sensor" do
    s = Space.new()
    c = Circle.new(s.static_body, 10)
    c.sensor = true
    s.add c
    hits = s.point_query(v(0, 0), 100, ShapeFilter.new())
    assert hits.size == 1
  end

  test "point_query_nearest" do
    s = Space.new()
    b1 = s.add Body.new(1, 1)
    b1.position = v(19, 0)
    s1 = s.add Circle.new(b1, 10)

    hit = s.point_query_nearest(v(23, 0))
    assert hit
    assert hit.shape == s1
    assert hit.point == v(29, 0)
    assert hit.distance == -6
    assert hit.gradient == v(1, 0)

    hit = s.point_query_nearest(v(30, 0))
    assert hit == nil

    hit = s.point_query_nearest(v(30, 0), 10)
    assert hit
    assert hit.shape == s1
    assert hit.point == v(29, 0)
    assert hit.distance == 1
    assert hit.gradient == v(1, 0)
  end

  test "point_query_nearest with sensor" do
    s = Space.new()
    c = Circle.new(s.static_body, 10)
    c.sensor = true
    s.add c
    hit = s.point_query_nearest(v(0, 0), 100, ShapeFilter.new())
    assert hit == nil
  end

  test "bb_query" do
    s = Space.new()

    b1 = s.add Body.new(1, 1)
    b1.position = v(19, 0)
    s1 = s.add Circle.new(b1, 10)

    b2 = s.add Body.new(1, 1)
    b2.position = v(0, 0)
    s2 = s.add Circle.new(b2, 10)

    bb = BB.new(-7, -7, 7, 7)
    hits = s.bb_query(bb)
    assert hits.size == 1
    assert hits.includes? s2
    assert !(hits.includes? s1)
  end

  test "bb_query with sensor" do
    s = Space.new()
    c = Circle.new(s.static_body, 10)
    c.sensor = true
    s.add c
    hits = s.bb_query(BB.new(0, 0, 10, 10), ShapeFilter.new())
    assert hits.size == 1
  end

  test "shape_query" do
    space = TestSpace.new()

    b = Body.new_kinematic()
    s = Circle.new(b, 2)
    b.position = v(20, 1)

    hits = space.shape_query(s)

    assert hits.size == 1
    assert hits[0] == space.s2
  end

  test "shape_query with sensor" do
    s = Space.new()
    c = Circle.new(s.static_body, 10)
    c.sensor = true
    s.add c
    hits = s.shape_query(Circle.new(nil, 200))
    assert hits.size == 1
  end

  test "static point queries" do
    s = TestSpace.new()

    b = s.add Body.new_kinematic()
    b.position = v(-50, -50)
    c = s.add Circle.new(b, 10)

    hit = s.point_query_nearest(v(-50, -50))
    assert hit && hit.shape == c

    hits = s.point_query(v(-50, -55), 0)
    assert hits[0].shape == c
  end

  test "reindex shape" do
    s = Space.new()

    b = s.add Body.new_kinematic()
    c = s.add Circle.new(b, 10)

    b.position = v(-50, -50)
    hit = s.point_query_nearest(v(-50, -55))
    assert hit == nil
    s.reindex c
    hit = s.point_query_nearest(v(-50, -55))
    assert hit
    assert hit.shape == c
  end

  test "reindex_shapes_for body" do
    s = Space.new()
    b = s.add Body.new_static()
    c = s.add Circle.new(b, 10)

    b.position = v(-50, -50)
    hit = s.point_query_nearest(v(-50, -55))
    assert hit == nil
    s.reindex_shapes_for b

    hit = s.point_query_nearest(v(-50, -55))
    assert hit && hit.shape == c
  end

  test "reindex_static" do
    s = Space.new()
    b = s.add Body.new_static()
    c = s.add Circle.new(b, 10)

    b.position = v(-50, -50)
    hit = s.point_query_nearest(v(-50, -55))
    assert hit == nil
    s.reindex_static()
    hit = s.point_query_nearest(v(-50, -55))
    assert hit && hit.shape == c
  end

  test "reindex_static collision" do
    s = Space.new()
    b1 = s.add Body.new(10, 1000)
    b1.position = v(20, 20)
    c1 = s.add Circle.new(b1, 10)

    b2 = s.add Body.new_static()
    s2 = s.add Segment.new(b2, v(-10, 0), v(10, 0), 1)

    s2.set_endpoints(v(-10, 0), v(100, 0))
    s.gravity = v(0, -100)

    10.times do
      s.step(0.1)
    end

    assert b1.position.y < 0

    b1.position = v(20, 20)
    b1.velocity = v(0, 0)
    s.reindex_static()

    10.times do
      s.step(0.1)
    end

    assert b1.position.y > 10
  end

  test "segment_query" do
    s = Space.new()

    b1 = s.add Body.new(1, 1)
    b1.position = v(19, 0)
    s1 = s.add Circle.new(b1, 10)

    b2 = s.add Body.new(1, 1)
    b2.position = v(0, 0)
    s2 = s.add Circle.new(b2, 10)

    hits = s.segment_query(v(-13, 0), v(131, 0))

    assert hits.size == 2
    assert hits[0].shape == s2
    assert hits[0].point == v(-10, 0)
    assert hits[0].normal == v(-1, 0)
    assert hits[0].alpha.close? 0.0208333333333

    assert hits[1].shape == s1
    assert hits[1].point == v(9, 0)
    assert hits[1].normal == v(-1, 0)
    assert hits[1].alpha.close? 0.1527777777777

    hits = s.segment_query(v(-13, 50), v(131, 50))
    assert hits.empty?
  end

  test "segment_query with sensor" do
    s = Space.new()
    c = Circle.new(s.static_body, 10)
    c.sensor = true
    s.add c
    hits = s.segment_query(v(-20, 0), v(20, 0), 1, ShapeFilter.new())
    assert hits.size == 1
  end

  test "segment_query_first" do
    s = Space.new()

    b1 = s.add Body.new(1, 1)
    b1.position = v(19, 0)
    s1 = s.add Circle.new(b1, 10)

    b2 = s.add Body.new(1, 1)
    b2.position = v(0, 0)
    s2 = s.add Circle.new(b2, 10)

    hit = s.segment_query_first(v(-13, 0), v(131, 0))
    assert hit
    assert hit.shape == s2
    assert hit.point == v(-10, 0)
    assert hit.normal == v(-1, 0)
    assert hit.alpha.close? 0.0208333333333

    hit = s.segment_query_first(v(-13, 50), v(131, 50))
    assert hit == nil
  end

  test "segment_query_first with sensor" do
    s = Space.new()
    c = Circle.new(s.static_body, 10)
    c.sensor = true
    s.add c
    hit = s.segment_query_first(v(-20, 0), v(20, 0), 1, ShapeFilter.new())
    assert hit == nil
  end

  test "static segment queries" do
    s = TestSpace.new()

    b = s.add Body.new_kinematic()
    b.position = v(-50, -50)
    c = s.add Circle.new(b, 10)

    hit = s.segment_query_first(v(-70, -50), v(-30, -50))
    assert hit && hit.shape == c

    hits = s.segment_query(v(-70, -50), v(-30, -50))
    assert hits[0].shape == c
  end

  describe "add_collision_handler" do
    test "begin" do
      s = Space.new()
      b1 = Body.new(1, 1)
      c1 = Circle.new(b1, 10)
      b2 = Body.new(1, 1)
      c2 = Circle.new(b2, 10)
      s.add b1, c1, b2, c2

      h = s.add_collision_handler(0, 0, BeginHandler.new)
      h.test = 1

      10.times do
        s.step(0.1)
      end

      assert h.hits == 1
    end

    test "pre_solve" do
      s = Space.new()
      b1 = Body.new(1, 1)
      c1 = Circle.new(b1, 10)
      c1.collision_type = 1
      b2 = Body.new(1, 1)
      c2 = Circle.new(b2, 10)
      s.add b1, c1, b2, c2

      h = s.add_collision_handler(0, 1, PreSolveHandler.new)
      s.step(0.1)
      assert h.shapes[1] == c1
      assert h.shapes[0] == c2
      assert h.space == s
    end

    test "post_solve" do
      s = TestSpace.new()

      h = s.add_collision_handler(0, 0, PostSolveHandler.new)
      s.step(0.1)
      assert h.hits == 1
    end

    test "separate" do
      s = Space.new()

      b1 = Body.new(1, 1)
      c1 = Circle.new(b1, 10)
      b1.position = v(9, 11)

      b2 = Body.new_static()
      c2 = Circle.new(b2, 10)
      b2.position = v(0, 0)

      s.add b1, c1, b2, c2
      s.gravity = v(0, -100)

      h = s.add_collision_handler(0, 0, SeparateHandler.new)

      10.times do
        s.step(0.1)
      end

      assert h.hits == 1
    end

    test "wildcard" do
      s = Space.new()
      b1 = Body.new(1, 1)
      c1 = Circle.new(b1, 10)
      b2 = Body.new(1, 1)
      c2 = Circle.new(b2, 10)
      s.add b1, c1, b2, c2

      h = s.add_collision_handler(1, PreSolveHandler.new)
      s.step(0.1)
      assert h.space == nil

      c1.collision_type = 1
      s.step(0.1)
      assert h.shapes[0] == c1
      assert h.shapes[1] == c2
      assert h.space == s
    end

    test "default" do
      s = Space.new()
      b1 = Body.new(1, 1)
      c1 = Circle.new(b1, 10)
      c1.collision_type = 1
      b2 = Body.new(1, 1)
      c2 = Circle.new(b2, 10)
      c2.collision_type = 2
      s.add b1, c1, b2, c2

      h = s.add_collision_handler(PreSolveHandler.new)
      s.step(0.1)
      assert h.shapes[1] == c1
      assert h.shapes[0] == c2
      assert h.space == s
    end
  end
end

class AddRemoveHandler < CollisionHandler
  def initialize(@b : Body, @c : Circle)
  end

  def pre_solve(arbiter, space)
    if !@b.space
      space.add @b, @c
      space.add @c, @b
      assert !(space.bodies.includes? @b)
      assert !(space.shapes.includes? @c)
    else
      space.remove @b, @c
      space.remove @c, @b
      assert space.bodies.includes? @b
      assert space.shapes.includes? @c
    end
    true
  end
end

class RemoveArbiterHandler < CollisionHandler
  def pre_solve(arbiter, space)
    space.remove *arbiter.shapes
    true
  end
end

class BeginHandler < CollisionHandler
  getter hits = 0
  property test = 0

  def begin(arbiter, space)
    @hits += @test
    true
  end
end

class PreSolveHandler < CollisionHandler
  getter shapes = [] of Shape
  getter space : Space?

  def pre_solve(arbiter, space)
    @shapes = arbiter.shapes.to_a
    @space = space
    true
  end
end

class PostSolveHandler < CollisionHandler
  getter hits = 0

  def post_solve(arbiter, space)
    @hits += 1
  end
end

class SeparateHandler < CollisionHandler
  getter hits = 0

  def separate(arbiter, space)
    @hits += 1
  end
end


describe Space::DebugDraw do
  test do
    s = Space.new()

    b1 = s.add Body.new(1, 3)
    s1 = s.add Circle.new(b1, 5)
    s.step(1)
    draw = TestDebugDraw.new()

    draw.draw(s)

    assert draw.calls == [%{
      draw_circle(pos: #{v(0.0, 0.0)}, angle: #{0.0}, radius: #{5.0},
                  outline_color: #{CP::Space::DebugDraw::Color.new(0.78431374_f32, 0.8235294_f32, 0.9019608_f32, 1.0_f32)},
                  fill_color: #{CP::Space::DebugDraw::Color.new(0.0_f32, 0.75_f32, 0.16432585_f32, 1.0_f32)})
    }].map &.split().join(" ")
  end
end

private macro def_draw(call)
  def draw_{{call}}
    {% args = call.args.map { |arg| "#{arg}: \#{ #{arg} }".id } %}
    @calls << "draw_{{call.name}}({{*args}})"
  end
end

class TestDebugDraw < Space::DebugDraw
  getter calls = [] of String

  def_draw circle(pos, angle, radius, outline_color, fill_color)
  def_draw segment(a, b, color)
  def_draw fat_segment(a, b, radius, outline_color, fill_color)
  def_draw polygon(verts, radius, outline_color, fill_color)
  def_draw dot(size, pos, color)
end
