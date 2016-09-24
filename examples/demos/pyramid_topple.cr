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

class PyramidTopple < Demo
  TITLE = "Pyramid Topple"
  SIM_FPS = 180

  WIDTH = 4.0
  HEIGHT = 30.0

  def initialize(window)
    super

    space = @space
    space.iterations = 30
    space.gravity = CP.v(0, -300)
    space.sleep_time_threshold = 0.5
    space.collision_slop = 0.5

    # Add a floor.
    shape = space.add CP::Segment.new(space.static_body, CP.v(-600, -240), CP.v(600, -240), 0.0)
    shape.elasticity = 1.0
    shape.friction = 1.0

    # Add the dominoes.
    n = 12
    (0...n).each do |i|
      (0...n-i).each do |j|
        offset = CP.v((j - (n - 1 - i)*0.5)*1.5*HEIGHT, (i + 0.5)*(HEIGHT + 2*WIDTH) - WIDTH - 240)
        add_domino(offset, false)
        add_domino(offset + CP.v(0, (HEIGHT + WIDTH)/2), true)

        if j == 0
          add_domino(offset + CP.v(0.5*(WIDTH - HEIGHT), HEIGHT + WIDTH), false)
        end

        if j != n - i - 1
          add_domino(offset + CP.v(HEIGHT*0.75, (HEIGHT + 3*WIDTH)/2.0), true)
        else
          add_domino(offset + CP.v(0.5*(HEIGHT - WIDTH), HEIGHT + WIDTH), false)
        end
      end
    end
  end

  def add_domino(pos, flipped = false)
    mass = 1.0
    radius = 0.5
    moment = CP::Box.moment(mass, WIDTH, HEIGHT)

    body = @space.add CP::Body.new(mass, moment)
    body.position = pos

    shape = if flipped
      CP::Box.new(body, HEIGHT, WIDTH, 0.0)
    else
      CP::Box.new(body, WIDTH - radius*2, HEIGHT, radius)
    end
    @space.add shape
    shape.elasticity = 0.0
    shape.friction = 0.6
  end
end


require "../demo/run"
