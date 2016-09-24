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

class Query < Demo
  TITLE = "Segment Query"

  def initialize(window)
    super

    @start = CP::Vect.new(0, 0)

    space = @space
    space.iterations = 5

    # add a fat segment
    mass = 1.0
    length = 100.0
    a = CP.v(-length/2.0, 0.0)
    b = CP.v(length/2.0, 0.0)

    body = space.add CP::Body.new(mass, CP::Segment.moment(mass, a, b, 0.0))
    body.position = CP.v(0.0, 100.0)

    space.add @seg = CP::Segment.new(body, a, b, 20.0)

    # add a static segment
    space.add CP::Segment.new(space.static_body, CP.v(0, 300), CP.v(300, 0), 0.0)

    # add a pentagon
    mass = 1.0
    verts = [] of CP::Vect

    5.times do |i|
      angle = -2.0 * Math::PI * i / 5
      verts << CP.v(30 * Math.cos(angle), 30 * Math.sin(angle))
    end

    body = space.add CP::Body.new(mass, CP::Poly.moment(mass, verts, CP.vzero, 0.0))
    body.position = CP.v(50.0, 30.0)

    space.add CP::Poly.new(body, verts, radius: 10)

    # add a circle
    mass = 1.0
    r = 20.0

    body = space.add CP::Body.new(mass, CP::Circle.moment(mass, 0.0, r, CP.vzero))
    body.position = CP.v(100.0, 100.0)

    space.add CP::Circle.new(body, r)
  end

  private def short(x : Number)
    x.round(3).to_s
  end
  private def short(v : CP::Vect)
    "#{short(v.x)}, #{short(v.y)}"
  end

  def draw()
    if @right_click
      @start = @mouse
    end

    start = @start
    finish = @mouse
    radius = 10.0
    draw_segment(start, finish, Color.new(0.0, 1.0, 0.0))

    @message = "Query: Dist(#{short(start.dist finish)}) \
                       Point(#{short(finish)})\n"

    if (info = @space.segment_query_first(start, finish, radius))
      # Draw blue over the occluded part of the query
      draw_segment(CP::Vect.lerp(start, finish, info.alpha), finish, Color.new(0.0, 0.0, 1.0))

      # Draw a little red surface normal
      draw_segment(info.point, info.point + info.normal * 16, Color.new(1.0, 0.0, 0.0))

      # Draw a little red dot on the hit point.
      draw_dot(3.0, info.point, Color.new(1.0, 0.0, 0.0))

      @message += "Segment Query: Dist(#{short(info.alpha * (start.dist finish))}) \
                                  Normal(#{short(info.normal)})"
    else
      @message += "Segment Query (None)"
    end

    # Draw a fat green line over the unoccluded part of the query
    draw_fat_segment(start, CP::Vect.lerp(start, finish, info ? info.alpha : 1.0), radius, Color.new(0.0, 1.0, 0.0), Color.gray(0.0, 0.0))

    if (info = @space.point_query_nearest(@mouse, 100.0))
      # Draw a grey line to the closest shape.
      draw_dot(3.0, @mouse, Color.new(0.5, 0.5, 0.5))
      draw_segment(@mouse, info.point, Color.new(0.5, 0.5, 0.5))

      # Draw a red bounding box around the shape under the mouse.
      if info.distance < 0
        draw_bb(info.shape.bb, Color.new(1.0, 0.0, 0.0, 1.0))
      end
    end

    super
  end
end


require "../demo/run"
