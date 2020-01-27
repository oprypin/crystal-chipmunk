require "./spec_helper"

describe Body do
  test "creation" do
    b1 = Body.new(1, 1)
    b2 = Body.new(1, 1)
    assert b1.type == Body::DYNAMIC
    assert b2.type == Body::DYNAMIC

    b = Body.new_kinematic()
    assert b.type == Body::KINEMATIC

    b = Body.new_static()
    assert b.type == Body::STATIC
  end

  test "properties" do
    b = Body.new(10, 100)

    assert b.mass == 10
    b.mass = 11
    assert b.mass == 11

    assert b.moment == 100
    b.moment = 101
    assert b.moment == 101

    assert b.position == vzero
    b.position = v(1, 2)
    assert b.position == v(1, 2)

    assert b.center_of_gravity == vzero
    b.center_of_gravity = v(2, 3)
    assert b.center_of_gravity == v(2, 3)

    assert b.velocity == vzero
    b.velocity = v(3, 4)
    assert b.velocity == v(3, 4)

    assert b.force == vzero
    b.force = v(4, 5)
    assert b.force == v(4, 5)

    assert b.angle == 0
    b.angle = 1.2
    assert b.angle == 1.2

    assert b.angular_velocity == 0
    b.angular_velocity = 1.3
    assert b.angular_velocity == 1.3

    assert b.torque == 0
    b.torque = 1.4
    assert b.torque == 1.4

    b.angle = 0
    assert b.rotation == v(1, 0)
    b.angle = v(1, 1).to_angle
    assert b.rotation.to_angle.close? v(1, 1).to_angle

    assert b.space == nil
    s = Space.new()
    s.add b
    assert b.space == s
  end

  test "coordinate conversion" do
    b = Body.new_kinematic()
    v = v(1, 2)
    assert b.local_to_world(v) == v
    assert b.world_to_local(v) == v
    b.position = v(3, 4)
    assert b.local_to_world(v) == v(4, 6)
    assert b.world_to_local(v) == v(-2, -2)
  end

  test "velocity conversion" do
    b = Body.new(1, 2)
    assert b.velocity_at_world_point(v(1, 1)) == v(0, 0)
    assert b.velocity_at_local_point(v(1, 1)) == v(0, 0)
    b.position = v(1, 2)
    b.angular_velocity = 1.2
    assert b.velocity_at_world_point(v(1, 1)) == v(1.2, 0)
    assert b.velocity_at_local_point(v(1, 1)) == v(-1.2, 1.2)
  end

  test "force" do
    b = Body.new(1, 2)
    b.position = v(3, 4)
    b.apply_force_at_world_point(v(10, 0), v(0, 10))
    assert b.force == v(10, 0)
    assert b.torque == -60

    b = Body.new(1, 2)
    b.position = v(3, 4)
    b.apply_force_at_local_point(v(10, 0), v(0, 10))
    assert b.force == v(10, 0)
    assert b.torque == -100
  end

  test "impulse" do
    b = Body.new(1, 2)
    b.position = v(3, 4)
    b.apply_impulse_at_world_point(v(10, 0), v(0, 10))
    assert b.velocity == v(10, 0)
    assert b.angular_velocity == -30

    b = Body.new(1, 2)
    b.position = v(3, 4)
    b.apply_impulse_at_local_point(v(10, 0), v(0, 10))
    assert b.velocity == v(10, 0)
    assert b.angular_velocity == -50
  end

  test "sleep" do
    b = Body.new(1, 1)
    s = Space.new()
    s.sleep_time_threshold = 0.01

    assert !b.sleeping?

    expect_raises(Exception) { b.sleep }
    s.add b
    b.sleep()

    assert b.sleeping?

    b.activate()
    assert !b.sleeping?

    b.sleep()
    s.remove b
    b.activate()
  end

  test "sleep_with_group" do
    b1 = Body.new(1, 1)
    b2 = Body.new(2, 2)
    s = Space.new()
    s.sleep_time_threshold = 0.01
    s.add b2
    b2.sleep()

    expect_raises(Exception) { b1.sleep_with_group(b2) }

    s.add b1
    b1.sleep_with_group(b2)
    assert b1.sleeping?
    b2.activate()
    assert !b1.sleeping?
  end

  test "kinetic_energy" do
    b = Body.new(1, 10)
    assert b.kinetic_energy == 0
    b.apply_impulse_at_local_point(v(10, 0), v(0, 0))
    assert b.kinetic_energy == 100
  end

  test "mass and moment from shape" do
    s = Space.new()

    b = Body.new()
    b.mass = 2
    c = Circle.new(b, 10, v(2, 3))
    c.mass = 3

    assert b.mass == 0
    s.add b, c
    assert b.mass == 3
    c.mass = 4
    assert b.mass == 4
    assert b.center_of_gravity.x == 2
    assert b.center_of_gravity.y == 3
    assert b.moment == 200
  end

  test "update_position" do
    s = Space.new()
    b = s.add PositionBody.new(1, 1)

    s.step(10)
    assert b.position == v(0, 10)
    s.step(1)
    s.step(1)
    assert b.position.y == 12

    b.default = true
    s.step(1)
    assert b.position.y == 12
  end

  test "update_velocity" do
    s = Space.new()
    s.gravity = v(1, 0)
    b = s.add VelocityBody.new(1, 1)

    s.step(10)
    assert b.velocity.x == 5
    s.step(0.1)
    s.step(0.1)
    assert b.velocity.x == 15

    b.default = true
    s.step(1)
    assert b.velocity.x == 16
  end

  test "each_arbiter" do
    s = Space.new()
    b1 = Body.new(1, 1)
    b2 = Body.new(2, 2)
    c1 = Circle.new(b1, 10)
    c2 = Circle.new(b2, 10)
    s.add b1, b2, c1, c2
    s.step(1)

    shapes = [] of Shape
    b1.each_arbiter do |arb|
      shapes += arb.shapes.to_a
    end
    assert shapes == [c1, c2]
  end

  test "constraints" do
    s = Space.new()
    b1 = s.add Body.new(1, 1)
    b2 = s.add Body.new(2, 2)
    j1 = s.add PivotJoint.new(b1, s.static_body, v(0, 0))
    j2 = s.add PivotJoint.new(b2, s.static_body, v(0, 0))

    assert b1.constraints.includes? j1
    assert !b2.constraints.includes? j1
    assert s.static_body.constraints.includes? j1
    assert s.static_body.constraints.includes? j2
  end

  test "shapes" do
    s = Space.new()
    b1 = s.add Body.new(1, 1)
    s1 = s.add Circle.new(b1, 3)
    s2 = s.add Segment.new(b1, v(0, 0), v(1, 2), 1)

    assert b1.shapes.includes? s1
    assert b1.shapes.includes? s2
    assert !s.static_body.shapes.includes? s1
  end
end

class PositionBody < Body
  setter default = false

  def update_position(dt)
    if @default
      super
    else
      self.position += v(0, dt)
    end
  end
end

class VelocityBody < Body
  setter default = false

  def update_velocity(gravity, damping, dt)
    if @default
      super
    else
      self.velocity += gravity * 5
    end
  end
end
