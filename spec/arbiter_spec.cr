require "./spec_helper"

class TestArbSpace < Space
  def initialize
    super

    @b1 = Body.new(1, 30)
    @c1 = Circle.new(@b1, 10)
    @b1.position = v(5, 3)
    @c1.collision_type = 1
    @c1.friction = 0.5

    @b2 = Body.new_static
    @c2 = Circle.new(@b2, 10)
    @c2.collision_type = 2
    @c2.friction = 0.8

    self.gravity = v(0, -100)
    add @b1, @c1, @b2, @c2
  end

  getter b1, c1, b2, c2
end

class RestitutionCollisionHandler < CollisionHandler
  def pre_solve(arb, space)
    assert arb.restitution == 0.18
    arb.restitution = 1
    true
  end
end

test "Arbiter / restitution" do
  s = Space.new
  s.gravity = v(0, -100)

  b1 = Body.new(1, 1)
  c1 = Circle.new(b1, 10)
  b1.position = v(0, 25)
  c1.collision_type = 1
  c1.elasticity = 0.6

  b2 = Body.new_static
  c2 = Circle.new(b2, 10)
  c2.collision_type = 2
  c2.elasticity = 0.3

  s.add b1, c1, b2, c2

  s.add_collision_handler(1, 2, RestitutionCollisionHandler.new)

  10.times do
    s.step(0.1)
  end

  assert b1.position.y.close? 22.42170317
end

class FrictionCollisionHandler < CollisionHandler
  def pre_solve(arb, space)
    assert arb.friction == 0.18
    arb.friction = 1
    true
  end
end

test "Arbiter / friction" do
  s = Space.new
  s.gravity = v(0, -100)

  b1 = Body.new(1, Float64::INFINITY)
  c1 = Circle.new(b1, 10)
  b1.position = v(10, 25)
  c1.collision_type = 1
  c1.friction = 0.6

  b2 = Body.new_static
  c2 = Circle.new(b2, 10)
  c2.collision_type = 2
  c2.friction = 0.3

  s.add b1, c1, b2, c2

  s.add_collision_handler(1, 2, FrictionCollisionHandler.new)

  10.times do
    s.step(0.1)
  end

  assert b1.position.x.close? 10.99450928394
end

class SurfaceVelocityCollisionHandler < CollisionHandler
  def pre_solve(arb, space)
    assert arb.surface_velocity.x.close? 1.38461538462
    assert arb.surface_velocity.y.close? -0.923076923077

    arb.surface_velocity = v(10, 10)

    true
  end
end

test "Arbiter / surface_velocity" do
  s = Space.new
  s.gravity = v(0, -100)

  b1 = Body.new(1, Float64::INFINITY)
  c1 = Circle.new(b1, 10)
  b1.position = v(10, 25)
  c1.collision_type = 1
  c1.surface_velocity = v(3, 0)

  b2 = Body.new_static
  c2 = Circle.new(b2, 10)
  c2.collision_type = 2
  c2.surface_velocity = v(5, 0)

  s.add b1, c1, b2, c2

  s.add_collision_handler(1, 2, SurfaceVelocityCollisionHandler.new)

  5.times do
    s.step(0.1)
  end
end

class ContactPointSetCollisionHandler < CollisionHandler
  def pre_solve(arb, space)
    # check inital values
    ps = arb.contact_point_set
    assert ps.points.size == 1
    assert ps.normal.x.close? 0.8574929257
    assert ps.normal.y.close? 0.5144957554
    p1 = ps.points[0]
    assert p1.point_a.x.close? 8.574929257
    assert p1.point_a.y.close? 5.144957554
    assert p1.point_b.x.close? -3.574929257
    assert p1.point_b.y.close? -2.144957554
    assert p1.distance.close? -14.16904810

    # check that they can be changed
    ps = ContactPointSet.new(Slice[ContactPoint.new(v(9, 10), v(-2, -3), -10)], v(1, 0))
    arb.contact_point_set = ps
    ps2 = arb.contact_point_set

    assert ps2.normal == v(1, 0)
    p1 = ps2.points[0]
    assert p1.point_a.x.close? 9
    assert p1.point_a.y.close? 10
    assert p1.point_b.x.close? -2
    assert p1.point_b.y.close? -3
    assert p1.distance.close? -11

    true
  end
end

test "Arbiter / contact_point_set" do
  s = TestArbSpace.new
  s.add_collision_handler(ContactPointSetCollisionHandler.new)

  s.step(0.1)
end

class ImpulseCollisionHandler < CollisionHandler
  getter post_solve_done = false

  def post_solve(arb, space)
    assert arb.total_impulse.x.close? 3.3936651583
    assert arb.total_impulse.y.close? 4.3438914027
    @post_solve_done = true
  end
end

test "Arbiter / impulse" do
  s = TestArbSpace.new
  s.add_collision_handler(1, 2, ch = ImpulseCollisionHandler.new)

  s.step(0.1)

  assert ch.post_solve_done
end

class TotalKECollisionHandler < CollisionHandler
  def post_solve(arb, space)
    assert arb.total_ke.close? 43.438914027
    true
  end
end

test "Arbiter / total_ke" do
  s = TestArbSpace.new
  s.add_collision_handler(1, 2, TotalKECollisionHandler.new)

  s.step(0.1)
end

class FirstContactCollisionHandler < CollisionHandler
  property? first_contact : Bool?

  def pre_solve(arb, space)
    @first_contact = arb.first_contact?
    true
  end
end

test "Arbiter / first_contact?" do
  s = TestArbSpace.new
  s.add_collision_handler(1, 2, ch = FirstContactCollisionHandler.new)

  ch.first_contact = nil
  s.step(0.1)
  assert ch.first_contact?

  ch.first_contact = nil
  s.step(0.1)
  assert !ch.first_contact?
end

class NormalCollisionHandler < CollisionHandler
  def pre_solve(arb, space)
    assert arb.normal.x.close? 0.44721359
    assert arb.normal.y.close? 0.89442719
    true
  end
end

test "Arbiter / normal" do
  s = Space.new()
  s.gravity = v(0, -100)

  b1 = Body.new(1, 30)
  b1.position = v(5, 10)
  c1 = Circle.new(b1, 10)
  c2 = Circle.new(s.static_body, 10)

  s.add b1, c1, c2

  s.add_collision_handler(ch = NormalCollisionHandler.new)

  s.step(0.1)
end

class RemovalCollisionHandler < CollisionHandler
  property? removal : Bool?

  def separate(arb, space)
    @removal = arb.removal?
  end
end

test "Arbiter / removal?" do
  s = TestArbSpace.new
  s.add_collision_handler(1, 2, ch = RemovalCollisionHandler.new)

  ch.removal = nil
  10.times do
    s.step(0.1)
  end
  assert !ch.removal?

  s.b1.position = v(5, 3)
  s.step(0.1)

  ch.removal = nil
  s.remove s.b1, s.c1
  assert ch.removal?
end

class ShapesCollisionHandler < CollisionHandler
  getter shapes : {Shape, Shape}?

  def pre_solve(arb, space)
    @shapes = arb.shapes
    true
  end
end

test "Arbiter / shapes" do
  s = TestArbSpace.new
  s.add_collision_handler(1, 2, ch = ShapesCollisionHandler.new)

  s.step(0.1)
  assert ch.shapes == {s.c1, s.c2}
end
