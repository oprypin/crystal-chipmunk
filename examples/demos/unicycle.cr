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

class Unicycle < Demo
  TITLE = "Unicycle"

  def initialize(window)
    super

    @message = "This unicycle is completely driven and balanced by a single SimpleMotor.\n\
                Move the mouse to make the unicycle follow it."

    space = @space
    space.iterations = 30
    space.gravity = CP.v(0, -500)


    [{CP.v(-3200, -240), CP.v(3200, -240)}, {CP.v(0, -200), CP.v(240, -240)}, {CP.v(-240, -240), CP.v(0, -200)}].each do |(a, b)|
      shape = space.add CP::Segment.new(space.static_body, a, b)
      shape.elasticity = 1
      shape.friction = 1
      shape.filter = NOGRAB_FILTER
    end


    radius = 20.0
    mass = 1.0

    wheel_body = space.add CP::Body.new
    wheel_body.position = CP.v(0.0, -160.0 + radius)
    shape = space.add CP::Circle.new(wheel_body, radius)
    shape.mass = mass
    shape.friction = 0.7
    shape.filter = CP::ShapeFilter.new(group: 1)


    cog_offset = 30.0
    mass = 3.0

    bb1 = CP::BB.new(-5.0, 0.0 - cog_offset, 5.0, cog_offset*1.2 - cog_offset)
    bb2 = CP::BB.new(-25.0, bb1.top, 25.0, bb1.top + 10.0)
    moment = CP::Box.moment(mass, bb1) + CP::Box.moment(mass, bb2)

    balance_body = space.add CP::Body.new(mass, moment)
    balance_body.position = CP.v(0.0, wheel_body.position.y + cog_offset)

    {bb1, bb2}.each do |bb|
      shape = space.add CP::Box.new(balance_body, bb, 0.0)
      shape.friction = 1.0
      shape.filter = CP::ShapeFilter.new(group: 1)
    end


    anchor_a = balance_body.world_to_local(wheel_body.position)
    groove_a = anchor_a + CP.v(0.0,  30.0)
    groove_b = anchor_a + CP.v(0.0, -10.0)
    space.add CP::GrooveJoint.new(balance_body, wheel_body, groove_a, groove_b, CP.vzero)
    space.add CP::DampedSpring.new(balance_body, wheel_body, anchor_a, CP.vzero,
      rest_length: 0, stiffness: 600, damping: 30
    )

    space.add @motor = Motor.new(wheel_body, balance_body, 0)


    width = 100.0
    height = 20.0
    mass = 3.0

    box_body = space.add CP::Body.new
    box_body.position = CP.v(200, -100)

    shape = space.add CP::Box.new(box_body, width, height)
    shape.mass = mass
    shape.friction = 0.7
  end

  def update
    @motor.target = @mouse.x

    super
  end

  def draw
    draw_segment(CP.v(@mouse.x, -1000.0), CP.v(@mouse.x, 1000.0), Color.new(1.0, 0.0, 0.0))

    super
  end

  class Motor < CP::SimpleMotor
    def initialize(@wheel_body : CP::Body, @balance_body : CP::Body, *args, **kwargs)
      super
      @balance_sin = 0.0
    end

    setter target = 0.0

    def pre_solve(space)
      dt = space.current_time_step

      max_v = 500.0;
      target_v = (bias_coef(0.5, dt/1.2)*(@target - @balance_body.position.x)/dt).clamp(-max_v, max_v)
      error_v = target_v - @balance_body.velocity.x
      target_sin = 3.0e-3*bias_coef(0.1, dt)*error_v/dt

      max_sin = Math.sin(0.6)
      @balance_sin = (@balance_sin - 6.0e-5*bias_coef(0.2, dt)*error_v/dt).clamp(-max_sin, max_sin)
      target_a = Math.asin((-target_sin + @balance_sin).clamp(-max_sin, max_sin))
      angular_diff = Math.asin(@balance_body.rotation.cross CP::Vect.angle(target_a))
      target_w = bias_coef(0.1, dt/0.4)*(angular_diff)/dt

      max_rate = 50.0
      rate = (@wheel_body.angular_velocity + @balance_body.angular_velocity - target_w).clamp(-max_rate, max_rate)
      self.rate = rate.clamp(-max_rate, max_rate)
      self.max_force = 8.0e4
    end

    private def bias_coef(error_bias, dt)
      1.0 - error_bias ** dt
    end
  end
end

require "../demo/run"
