# Copyright (c) 2007 Scott Lembcke
# Copyright (c) 2016 Oleh Prypin <oleh@pryp.in>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


require "../demo"

class Joints < Demo
  TITLE = "Joints and Constraints"

  def initialize(window)
    super

    space = @space
    space.iterations = 10
    space.gravity = CP.v(0, -100)
    space.sleep_time_threshold = 0.5

    static_body = space.static_body

    -240.step to: 240, by: 120 do |y|
      shape = space.add CP::Segment.new(static_body, CP.v(-320, y), CP.v(320, y))
      shape.elasticity = 1.0
      shape.friction = 1.0
      shape.filter = NOGRAB_FILTER
    end

    -320.step to: 320, by: 160 do |x|
      shape = space.add CP::Segment.new(static_body, CP.v(x, -240), CP.v(x, 240))
      shape.elasticity = 1.0
      shape.friction = 1.0
      shape.filter = NOGRAB_FILTER
    end

    pos_a = CP.v( 50, 60)
    pos_b = CP.v(110, 60)

    # Pin Joints - Link shapes with a solid bar or pin.
    # Keeps the anchor points the same distance apart from when the joint was created.
    box_offset = CP.v(-320, -240)
    body1 = add_ball(pos_a, box_offset)
    body2 = add_ball(pos_b, box_offset)
    space.add CP::PinJoint.new(body1, body2, CP.v(15, 0), CP.v(-15, 0))

    # Slide Joints - Like pin joints but with a min/max distance.
    # Can be used for a cheap approximation of a rope.
    box_offset = CP.v(-160, -240)
    body1 = add_ball(pos_a, box_offset)
    body2 = add_ball(pos_b, box_offset)
    space.add CP::SlideJoint.new(body1, body2, CP.v(15, 0), CP.v(-15, 0), 20.0, 40.0)

    # Pivot Joints - Holds the two anchor points together. Like a swivel.
    box_offset = CP.v(0, -240)
    body1 = add_ball(pos_a, box_offset)
    body2 = add_ball(pos_b, box_offset)
    space.add CP::PivotJoint.new(body1, body2, box_offset + CP.v(80, 60))

    # Groove Joints - Like a pivot joint, but one of the anchors is a line segment that the pivot can slide in
    box_offset = CP.v(160, -240)
    body1 = add_ball(pos_a, box_offset)
    body2 = add_ball(pos_b, box_offset)
    space.add CP::GrooveJoint.new(body1, body2, CP.v(30, 30), CP.v(30, -30), CP.v(-30, 0))

    # Damped Springs
    box_offset = CP.v(-320, -120)
    body1 = add_ball(pos_a, box_offset)
    body2 = add_ball(pos_b, box_offset)
    space.add CP::DampedSpring.new(body1, body2, CP.v(15, 0), CP.v(-15, 0), 20.0, 5.0, 0.3)

    # Damped Rotary Springs
    box_offset = CP.v(-160, -120)
    body1 = add_bar(pos_a, box_offset)
    body2 = add_bar(pos_b, box_offset)
    # Add some pin joints to hold the circles in place.
    space.add CP::PivotJoint.new(body1, static_body, box_offset + pos_a)
    space.add CP::PivotJoint.new(body2, static_body, box_offset + pos_b)
    space.add CP::DampedRotarySpring.new(body1, body2, 0.0, 3000.0, 60.0)

    # Rotary Limit Joint
    box_offset = CP.v(0, -120)
    body1 = add_lever(pos_a, box_offset)
    body2 = add_lever(pos_b, box_offset)
    # Add some pin joints to hold the circles in place.
    space.add CP::PivotJoint.new(body1, static_body, box_offset + pos_a)
    space.add CP::PivotJoint.new(body2, static_body, box_offset + pos_b)
    # Hold their rotation within 90 degrees of each other.
    space.add CP::RotaryLimitJoint.new(body1, body2, -Math::PI / 2, Math::PI / 2)

    # Ratchet Joint - A rotary ratchet, like a socket wrench
    box_offset = CP.v(160, -120)
    body1 = add_lever(pos_a, box_offset)
    body2 = add_lever(pos_b, box_offset)
    # Add some pin joints to hold the circles in place.
    space.add CP::PivotJoint.new(body1, static_body, box_offset + pos_a)
    space.add CP::PivotJoint.new(body2, static_body, box_offset + pos_b)
    # Ratchet every 90 degrees
    space.add CP::RatchetJoint.new(body1, body2, 0.0, Math::PI / 2)

    # Gear Joint - Maintain a specific angular velocity ratio
    box_offset = CP.v(-320, 0)
    body1 = add_bar(pos_a, box_offset)
    body2 = add_bar(pos_b, box_offset)
    # Add some pin joints to hold the circles in place.
    space.add CP::PivotJoint.new(body1, static_body, box_offset + pos_a)
    space.add CP::PivotJoint.new(body2, static_body, box_offset + pos_b)
    # Force one to sping 2x as fast as the other
    space.add CP::GearJoint.new(body1, body2, 0.0, 2.0)

    # Simple Motor - Maintain a specific angular relative velocity
    box_offset = CP.v(-160, 0)
    body1 = add_bar(pos_a, box_offset)
    body2 = add_bar(pos_b, box_offset)
    # Add some pin joints to hold the circles in place.
    space.add CP::PivotJoint.new(body1, static_body, box_offset + pos_a)
    space.add CP::PivotJoint.new(body2, static_body, box_offset + pos_b)
    # Make them spin at 1/2 revolution per second in relation to each other.
    space.add CP::SimpleMotor.new(body1, body2, Math::PI)

    # Make a car with some nice soft suspension
    box_offset = CP.v(0, 0)
    wheel1 = add_wheel(pos_a, box_offset)
    wheel2 = add_wheel(pos_b, box_offset)
    chassis = add_chassis(CP.v(80, 100), box_offset)

    space.add CP::GrooveJoint.new(chassis, wheel1, CP.v(-30, -10), CP.v(-30, -40), CP.vzero)
    space.add CP::GrooveJoint.new(chassis, wheel2, CP.v( 30, -10), CP.v( 30, -40), CP.vzero)

    space.add CP::DampedSpring.new(chassis, wheel1, CP.v(-30, 0), CP.vzero, 50.0, 20.0, 10.0)
    space.add CP::DampedSpring.new(chassis, wheel2, CP.v( 30, 0), CP.vzero, 50.0, 20.0, 10.0)
  end

  def add_ball(pos, box_offset)
    body = @space.add CP::Body.new
    body.position = pos + box_offset

    shape = @space.add CP::Circle.new(body, 15.0)
    shape.mass = 1.0
    shape.elasticity = 0.0
    shape.friction = 0.7

    body
  end

  def add_lever(pos, box_offset)
    body = @space.add CP::Body.new
    body.position = pos + box_offset + CP.v(0, -15)

    shape = @space.add CP::Segment.new(body, CP.v(0, -15), CP.v(0, 15), radius: 5.0)
    shape.mass = 1.0
    shape.elasticity = 0.0
    shape.friction = 0.7

    body
  end

  def add_bar(pos, box_offset)
    body = @space.add CP::Body.new
    body.position = pos + box_offset

    shape = @space.add CP::Segment.new(body, CP.v(0,  30), CP.v(0, -30), radius: 5.0)
    shape.mass = 2.0
    shape.elasticity = 0.0
    shape.friction = 0.7
    shape.filter = CP::ShapeFilter.new(group: 1)

    body
  end

  def add_wheel(pos, box_offset)
    body = @space.add CP::Body.new
    body.position = pos + box_offset

    shape = @space.add CP::Circle.new(body, 15.0)
    shape.mass = 1.0
    shape.elasticity = 0.0
    shape.friction = 0.7
    shape.filter = CP::ShapeFilter.new(group: 1)

    body
  end

  def add_chassis(pos, box_offset)
    body = @space.add CP::Body.new
    body.position = pos + box_offset

    shape = @space.add CP::Box.new(body, width: 80, height: 30)
    shape.mass = 5.0
    shape.elasticity = 0.0
    shape.friction = 0.7
    shape.filter = CP::ShapeFilter.new(group: 1)

    body
  end
end


require "../demo/run"
