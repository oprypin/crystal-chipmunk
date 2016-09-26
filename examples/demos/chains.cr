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

class Chains < Demo
  TITLE = "Breakable Chains"
  SIM_FPS = 180

  CHAIN_COUNT = 8
  LINK_COUNT = 10

  def initialize(window)
    super

    space = @space
    space.iterations = 30
    space.gravity = CP.v(0, -100)
    space.sleep_time_threshold = 0.5

    # Create segments around the edge of the screen.
    [{1, 1}, {1, -1}, {-1, -1}, {-1, 1}, {1, 1}].each_cons(2) do |(a, b)|
      shape = space.add CP::Segment.new(space.static_body,
        CP.v(320 * a[0], 240 * a[1]), CP.v(320 * b[0], 240 * b[1])
      )
      shape.elasticity = 1
      shape.friction = 1
      shape.filter = NOGRAB_FILTER
    end

    mass = 1
    width = 20
    height = 30

    spacing = width*0.3

    # Add lots of boxes.
    CHAIN_COUNT.times do |i|
      prev = nil

      LINK_COUNT.times do |j|
        pos = CP.v(40*(i - (CHAIN_COUNT - 1)/2.0), 240 - (j + 0.5)*height - (j + 1)*spacing)

        body = space.add CP::Body.new
        body.position = pos

        shape = space.add CP::Segment.new(body, CP.v(0, (height - width)/2.0), CP.v(0, (width - height)/2.0), width/2.0)
        shape.mass = mass
        shape.friction = 0.8

        constraint = space.add(
          if !prev
            BreakableJoint.new(body, space.static_body, CP.v(0, height/2), CP.v(pos.x, 240), 0, spacing)
          else
            BreakableJoint.new(body, prev, CP.v(0, height/2), CP.v(0, -height/2), 0, spacing)
          end
        )
        constraint.max_force = 80000
        constraint.collide_bodies = false

        prev = body
      end
    end

    radius = 15.0
    body = space.add CP::Body.new
    body.position = CP.v(0, -240 + radius+5)
    body.velocity = CP.v(0, 300)

    shape = space.add CP::Circle.new(body, radius)
    shape.mass = 10.0
    shape.elasticity = 0.0
    shape.friction = 0.9
  end

  class BreakableJoint < CP::SlideJoint
    def post_solve(space)
      # Convert the impulse to a force by dividing it by the timestep.
      force = impulse / space.current_time_step

      # If the force is almost as big as the joint's max force, break it.
      if force > 0.9*max_force
        space.remove self
      end
    end
  end
end

require "../demo/run"
