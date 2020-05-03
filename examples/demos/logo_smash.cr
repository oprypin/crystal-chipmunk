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

class LogoSmash < Demo
  TITLE = "Logo Smash"

  def initialize(window)
    super

    space = @space
    space.iterations = 1

    @draw.flags &=~ CP::Space::DebugDraw::DRAW_COLLISION_POINTS

    # The space will contain a very large number of similarly sized objects.
    # This is the perfect candidate for using the spatial hash.
    # Generally you will never need to do this.
    space.use_spatial_hash(2.0, 10000)

    image = read_pbm("../examples/resources/chipmunk_logo.pbm")
    height = image.size
    width = image[0].size

    image.each_with_index do |line, y|
      line.each_with_index do |p, x|
        next if p

        x_jitter = 0.05 * rand
        y_jitter = 0.05 * rand

        add_ball(2*(x - width/2 + x_jitter), 2*(height/2 - y + y_jitter))
      end
    end

    body = space.add CP::Body.new(1e9, Float64::INFINITY)
    body.position = CP.v(-1000, -10)
    body.velocity = CP.v(400, 0)

    shape = space.add CP::Circle.new(body, 8.0)
    shape.elasticity = 0.0
    shape.friction = 0.0
    shape.filter = NOGRAB_FILTER
  end

  def add_ball(x, y)
    body = @space.add CP::Body.new(1.0, Float64::INFINITY)
    body.position = CP.v(x, y)

    shape = @space.add CP::Circle.new(body, 0.95)
    shape.elasticity = 0.0
    shape.friction = 0.0

    shape
  end
end


def read_pbm(filename)
  File.open(filename) do |f|
    f.read_line
    width = f.read_line.to_i
    height = f.read_line.to_i

    Array.new(height) {
      bits = 0
      byte = 0u8
      Array(Bool).new(width) {
        if bits == 0
          byte = f.read_byte.not_nil!
          bits = 8
        end
        byte & 1u8 << (bits -= 1) != 0
      }
    }
  end
end


require "../demo/run"
