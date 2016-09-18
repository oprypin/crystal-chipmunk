require "./spec_helper"

describe Constraint do
  test "body_a" do
    a, b = Body.new(10, 10), Body.new(10, 10)
    j = PivotJoint.new(a, b, v(0, 0))
    assert j.body_a == a
  end

  test "body_b" do
    a, b = Body.new(10, 10), Body.new(10, 10)
    j = PivotJoint.new(a, b, v(0, 0))
    assert j.body_b == b
  end

  test "max_force" do
    a, b = Body.new(10, 10), Body.new(10, 10)
    j = PivotJoint.new(a, b, v(0, 0))
    assert j.max_force == Float64::INFINITY
    j.max_force = 10
    assert j.max_force == 10
  end

  test "error_bias" do
    a, b = Body.new(10, 10), Body.new(10, 10)
    j = PivotJoint.new(a, b, v(0, 0))
    assert j.error_bias.close?((1.0 - 0.1) ** 60.0, rel_tol: 1e-4)
    j.error_bias = 0.3
    assert j.error_bias == 0.3
  end

  test "max_bias" do
    a, b = Body.new(10, 10), Body.new(10, 10)
    j = PivotJoint.new(a, b, v(0, 0))
    assert j.max_bias == Float64::INFINITY
    j.max_bias = 10
    assert j.max_bias == 10
  end

  test "collide_bodies?" do
    a, b = Body.new(10, 10), Body.new(10, 10)
    j = PivotJoint.new(a, b, v(0, 0))
    assert j.collide_bodies? == true
    j.collide_bodies = false
    assert j.collide_bodies? == false
  end

  test "impulse" do
    a, b = Body.new(10, 10), Body.new(10, 10)
    b.position = v(0, 10)
    j = PivotJoint.new(a, b, v(0, 0))

    s = Space.new()
    s.gravity = v(0, 10)
    s.add b, j
    assert j.impulse == 0
    s.step(1)
    assert j.impulse.close? 50
  end

  test "bodies" do
    a, b = Body.new(4, 5), Body.new(10, 10)
    j = PivotJoint.new(a, b, v(0, 0))
    s = Space.new()
    s.sleep_time_threshold = 0.01
    s.add a, b
    a.sleep()
    b.sleep()

    j.bodies.each &.activate
    assert !a.sleeping?
    assert !b.sleeping?
  end
end

describe PinJoint do
  test "anchors" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = PinJoint.new(a, b, v(1, 2), v(3, 4))
    assert j.anchor_a == v(1, 2)
    assert j.anchor_b == v(3, 4)
    j.anchor_a = v(5, 6)
    j.anchor_b = v(7, 8)
    assert j.anchor_a == v(5, 6)
    assert j.anchor_b == v(7, 8)
  end

  test "dist" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = PinJoint.new(a, b, v(0, 0), v(10, 0))
    assert j.dist == 10
    j.dist = 20
    assert j.dist == 20
  end
end

describe SlideJoint do
  test "anchors" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = SlideJoint.new(a, b, v(1, 2), v(3, 4), 0, 10)
    assert j.anchor_a == v(1, 2)
    assert j.anchor_b == v(3, 4)
    j.anchor_a = v(5, 6)
    j.anchor_b = v(7, 8)
    assert j.anchor_a == v(5, 6)
    assert j.anchor_b == v(7, 8)
  end

  test "min" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = SlideJoint.new(a, b, v(0, 0), v(0, 0), 1, 0)
    assert j.min == 1
    j.min = 2
    assert j.min == 2
  end

  test "max" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = SlideJoint.new(a, b, v(0, 0), v(0, 0), 0, 1)
    assert j.max == 1
    j.max = 2
    assert j.max == 2
  end
end

describe PivotJoint do
  test "anchors by pivot" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    a.position = v(5, 7)
    j = PivotJoint.new(a, b, v(1, 2))
    assert j.anchor_a == v(-4, -5)
    assert j.anchor_b == v(1, 2)
  end

  test "anchors by anchor" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = PivotJoint.new(a, b, v(1, 2), v(3, 4))
    assert j.anchor_a == v(1, 2)
    assert j.anchor_b == v(3, 4)
    j.anchor_a = v(5, 6)
    j.anchor_b = v(7, 8)
    assert j.anchor_a == v(5, 6)
    assert j.anchor_b == v(7, 8)
  end
end

describe GrooveJoint do
  test "anchors" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = GrooveJoint.new(a, b, v(0, 0), v(0, 0), v(1, 2))
    assert j.anchor_b == v(1, 2)
    j.anchor_b = v(3, 4)
    assert j.anchor_b == v(3, 4)
  end

  test "groove" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = GrooveJoint.new(a, b, v(1, 2), v(3, 4), v(0, 0))
    assert j.groove_a == v(1, 2)
    assert j.groove_b == v(3, 4)
    j.groove_a = v(5, 6)
    j.groove_b = v(7, 8)
    assert j.groove_a == v(5, 6)
    assert j.groove_b == v(7, 8)
  end
end

describe DampedSpring do
  test "anchors" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = DampedSpring.new(a, b, v(1, 2), v(3, 4), 0, 0, 0)
    assert j.anchor_a == v(1, 2)
    assert j.anchor_b == v(3, 4)
    j.anchor_a = v(5, 6)
    j.anchor_b = v(7, 8)
    assert j.anchor_a == v(5, 6)
    assert j.anchor_b == v(7, 8)
  end

  test "rest_length" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = DampedSpring.new(a, b, v(0, 0), v(0, 0), 1, 0, 0)
    assert j.rest_length == 1
    j.rest_length = 2
    assert j.rest_length == 2
  end

  test "stiffness" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = DampedSpring.new(a, b, v(0, 0), v(0, 0), 0, 1, 0)
    assert j.stiffness == 1
    j.stiffness = 2
    assert j.stiffness == 2
  end

  test "damping" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = DampedSpring.new(a, b, v(0, 0), v(0, 0), 0, 0, 1)
    assert j.damping == 1
    j.damping = 2
    assert j.damping == 2
  end
end

describe DampedRotarySpring do
  test "rest_angle" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = DampedRotarySpring.new(a, b, 1, 0, 0)
    assert j.rest_angle == 1
    j.rest_angle = 2
    assert j.rest_angle == 2
  end

  test "stiffness" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = DampedRotarySpring.new(a, b, 0, 1, 0)
    assert j.stiffness == 1
    j.stiffness = 2
    assert j.stiffness == 2
  end

  test "damping" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = DampedRotarySpring.new(a, b,  0, 0, 1)
    assert j.damping == 1
    j.damping = 2
    assert j.damping == 2
  end
end

describe RotaryLimitJoint do
  test "min" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = RotaryLimitJoint.new(a, b, 1, 0)
    assert j.min == 1
    j.min = 2
    assert j.min == 2
  end

  test "max" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = RotaryLimitJoint.new(a, b, 0, 1)
    assert j.max == 1
    j.max = 2
    assert j.max == 2
  end
end

describe RatchetJoint do
  test "angle" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = RatchetJoint.new(a, b, 0, 0)
    assert j.angle == 0
    j.angle = 1
    assert j.angle == 1
  end

  test "phase" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = RatchetJoint.new(a, b, 1, 0)
    assert j.phase == 1
    j.phase = 2
    assert j.phase == 2
  end

  test "ratchet" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = RatchetJoint.new(a, b, 0, 1)
    assert j.ratchet == 1
    j.ratchet = 2
    assert j.ratchet == 2
  end
end

describe GearJoint do
  test "phase" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = GearJoint.new(a, b, 1, 0)
    assert j.phase == 1
    j.phase = 2
    assert j.phase == 2
  end

  test "ratio" do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = GearJoint.new(a, b, 0, 1)
    assert j.ratio == 1
    j.ratio = 2
    assert j.ratio == 2
  end
end

describe SimpleMotor do
  test do
    a, b = Body.new(10, 10), Body.new(20, 20)
    j = SimpleMotor.new(a, b, 0.3)
    assert j.rate == 0.3
    j.rate = 0.4
    assert j.rate == 0.4
  end
end
