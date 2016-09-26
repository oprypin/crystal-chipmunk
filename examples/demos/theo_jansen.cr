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

class TheoJansen < Demo
  TITLE = "Theo Jansen Machine"
  SIM_FPS = 180

  def initialize(window)
    super

    @message = "Use the arrow keys to control the machine."

    space = @space
    space.iterations = 20
    space.gravity = CP.v(0, -500)

    # Create segments around the edge of the screen.
    [{1, 1}, {1, -1}, {-1, -1}, {-1, 1}].each_cons(2) do |(a, b)|
      shape = space.add CP::Segment.new(space.static_body,
        CP.v(320 * a[0], 240 * a[1]), CP.v(320 * b[0], 240 * b[1]), 0.0
      )
      shape.elasticity = 1
      shape.friction = 1
    end

    offset = 30.0
    seg_radius = 3.0

    # make chassis
    a = CP.v(-offset, 0.0)
    b = CP.v(offset, 0.0)
    chassis = space.add CP::Body.new

    shape = space.add CP::Segment.new(chassis, a, b, seg_radius)
    shape.mass = 2.0
    shape.filter = CP::ShapeFilter.new(group: 1)

    # make crank
    crank = space.add CP::Body.new

    shape = space.add CP::Circle.new(crank, crank_radius = 13.0, CP.vzero)
    shape.mass = 1.0
    shape.filter = CP::ShapeFilter.new(group: 1)

    space.add CP::PivotJoint.new(chassis, crank, CP.vzero, CP.vzero)

    side = 30.0

    4.times do |i|
      anchor = CP::Vect.angle(Math::PI * i / 2) * crank_radius

      leg_mass = 1.0

      # make leg
      a = CP.vzero
      b = CP.v(0, side)
      upper_leg = space.add CP::Body.new(leg_mass, CP::Segment.moment(leg_mass, a, b, 1.0))
      upper_leg.position = CP.v(offset, 0.0)

      shape = space.add CP::Segment.new(upper_leg, a, b, seg_radius)
      shape.filter = CP::ShapeFilter.new(group: 1)

      space.add CP::PivotJoint.new(chassis, upper_leg, CP.v(offset, 0.0), CP.vzero)

      # lower leg
      a = CP.vzero
      b = CP.v(0, -1*side)
      lower_leg = space.add CP::Body.new(leg_mass, CP::Segment.moment(leg_mass, a, b, 0.0))
      lower_leg.position = CP.v(offset, -side)

      shape = space.add CP::Segment.new(lower_leg, a, b, seg_radius)
      shape.filter = CP::ShapeFilter.new(group: 1)

      shape = space.add CP::Circle.new(lower_leg, seg_radius*2.0, b)
      shape.filter = CP::ShapeFilter.new(group: 1)
      shape.elasticity = 0.0
      shape.friction = 1.0

      space.add CP::PinJoint.new(chassis, lower_leg, CP.v(offset, 0.0), CP.vzero)

      space.add CP::GearJoint.new(upper_leg, lower_leg, 0.0, 1.0)

      diag = Math.hypot(side, offset)

      constraint = space.add CP::PinJoint.new(crank, upper_leg, anchor, CP.v(0.0, side))
      constraint.dist = diag

      constraint = space.add CP::PinJoint.new(crank, lower_leg, anchor, CP.vzero)
      constraint.dist = diag

      offset *= -1
    end

    @motor = CP::SimpleMotor.new(chassis, crank, 6.0)
    space.add @motor
  end

  def update()
    coef = (2.0 + @keyboard.y) / 3.0
    rate = @keyboard.x * 10.0 * coef
    @motor.rate = rate
    @motor.max_force = (rate != 0.0 ? 100000 : 0)

    super
  end
end


require "../demo/run"
