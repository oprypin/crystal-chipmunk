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

class Sliced < Demo
  TITLE = "Slice"

  DENSITY = 1.0/10000.0

  def initialize(window)
    super

    @message = "Right click and drag to slice up the block."

    @prev_right_down = false
    @slice_start = CP::Vect.new(0, 0)

    space = @space
    space.iterations = 30
    space.gravity = CP.v(0, -500)
    space.sleep_time_threshold = 0.5
    space.collision_slop = 0.5

    shape = space.add CP::Segment.new(space.static_body, CP.v(-1000, -240), CP.v(1000, -240))
    shape.elasticity = 1.0
    shape.friction = 1.0
    shape.filter = NOGRAB_FILTER

    body = space.add CP::Body.new()
    shape = space.add CP::Box.new(body, 200, 300)
    shape.density = DENSITY
    shape.friction = 0.6
  end

  def update()
    super

    if @right_down != @prev_right_down
      if @right_down
        @slice_start = @mouse
      else
        # Check that the slice was complete by checking that the endpoints aren't in the sliced shape.
        @space.segment_query(a = @slice_start, b = @mouse, 0.0, GRAB_FILTER).each do |info|
          shape = info.shape.as CP::Poly

          if shape.point_query(a).distance > 0 && shape.point_query(b).distance > 0
            # Clipping plane normal and distance.
            n = (b - a).perp.normalize
            dist = a.dot n

            clip_poly(shape, n, dist)
            clip_poly(shape, -n, -dist)

            @space.remove shape, shape.body.not_nil!
          end
        end
      end

      @prev_right_down = @right_down
    end
  end

  def draw()
    super

    if @right_down
      draw_segment(@slice_start, @mouse, Color.new(1.0, 0.0, 0.0))
    end
  end

  def clip_poly(shape, n, dist)
    body = shape.body.not_nil!

    clipped = [] of CP::Vect

    shape.each_index do |i|
      a = body.local_to_world(shape[i-1])
      b = body.local_to_world(shape[i])

      a_dist = a.dot(n) - dist
      b_dist = b.dot(n) - dist

      if a_dist < 0
        clipped << a
      end

      if a_dist * b_dist < 0
        t = a_dist.abs / (a_dist.abs + b_dist.abs)

        clipped << CP::Vect.lerp(a, b, t)
      end
    end

    centroid = CP::Poly.centroid(clipped)
    mass = CP::Poly.area(clipped) * DENSITY
    moment = CP::Poly.moment(mass, clipped, -centroid)

    new_body = @space.add CP::Body.new(mass, moment)
    new_body.position = centroid
    new_body.velocity = body.velocity_at_world_point(centroid)
    new_body.angular_velocity = body.angular_velocity

    transform = CP::Transform.translate(-centroid)
    new_shape = @space.add CP::Poly.new(new_body, clipped, transform)
    # Copy whatever properties you have set on the original shape that are important
    new_shape.friction = shape.friction
  end
end


require "../demo/run"
