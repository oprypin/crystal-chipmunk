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

require "chipmunk/chipmunk_crsfml"


class Demo
  TITLE = "crystal-chipmunk"
  SIM_FPS = 60

  FONT = SF::Font.from_file("../examples/resources/font/Cantarell-Regular.otf")

  GRABBABLE_MASK = CP::ShapeFilter::Bitmask.new(1u32 << 31)
  GRAB_FILTER = CP::ShapeFilter.new(CP::ShapeFilter::NO_GROUP, GRABBABLE_MASK, GRABBABLE_MASK)
  NOGRAB_FILTER = CP::ShapeFilter.new(CP::ShapeFilter::NO_GROUP, ~GRABBABLE_MASK, ~GRABBABLE_MASK)

  alias Color = SFMLDebugDraw::Color

  def initialize(@window : SF::RenderWindow)
    @draw = SFMLDebugDraw.new(window)

    @running = false

    @runtime_clock = SF::Clock.new
    @sim_time = 0f32

    @space = CP::Space.new

    @mouse_body = CP::Body.new_kinematic()

    @text = SF::Text.new("", FONT, 18)
    @text.position = {10, 10}

    @keyboard = CP::Vect.new(0.0, 0.0)
    @mouse = CP::Vect.new(0.0, 0.0)
    @right_click = false
    @right_down = false
    @message = ""

    rescale
  end
  @mouse_joint : CP::PivotJoint?

  getter keyboard, mouse

  forward_missing_to @draw

  def rescale
    scale = {@window.size.x / (640 + 10.0), @window.size.y / (480 + 10.0)}.min
    @draw.states = SF::RenderStates.new(
      SF::Transform.new.translate(@window.view.size / 2).scale(scale, -scale)
    )
  end

  def run
    @runtime_clock.restart
    @sim_time = 0f32

    rescale
    @running = true

    while @running
      @keyboard = CP.vzero
      @keyboard.x += 1.0 if SF::Keyboard.key_pressed?(SF::Keyboard::Right)
      @keyboard.x -= 1.0 if SF::Keyboard.key_pressed?(SF::Keyboard::Left)
      @keyboard.y += 1.0 if SF::Keyboard.key_pressed?(SF::Keyboard::Up)
      @keyboard.y -= 1.0 if SF::Keyboard.key_pressed?(SF::Keyboard::Down)

      mouse = states.transform.inverse.transform_point(SF::Mouse.get_position(@window))
      @mouse = CP.v(mouse.x, mouse.y)

      while event = @window.poll_event
        case event
        when SF::Event::Closed
          @running = false
        when SF::Event::KeyPressed
          if event.code == SF::Keyboard::Escape
            @running = false
          end
        when SF::Event::Resized
          @window.view = SF::View.new(SF.float_rect(0, 0, event.width, event.height))
          rescale
        when SF::Event::MouseButtonPressed
          if event.button == SF::Mouse::Left
            # give the mouse click a little radius to make it easier to click small shapes
            radius = 5.0

            if (info = @space.point_query_nearest(@mouse, radius, GRAB_FILTER))
              shape = info.shape
              if (body = shape.body) && body.mass < Float64::INFINITY
                # Use the closest point on the surface if the click is outside of the shape.
                nearest = (info.distance > 0.0 ? info.point : @mouse)

                mouse_joint = CP::PivotJoint.new(@mouse_body, body, CP.vzero, body.world_to_local(nearest))
                mouse_joint.max_force = 50000.0
                mouse_joint.error_bias = (1.0 - 0.15)**60.0
                @space.add(@mouse_joint = mouse_joint)
              end
            end
          elsif event.button == SF::Mouse::Right
            @right_click = true
          end
        when SF::Event::MouseButtonReleased
          if (mouse_joint = @mouse_joint)
            @space.remove mouse_joint
            @mouse_joint = nil
          end
        end
      end

      new_point = CP::Vect.lerp(@mouse_body.@body.p, @mouse, 0.25)
      @mouse_body.velocity = (new_point - @mouse_body.@body.p) * 60.0
      @mouse_body.@body.p = new_point

      @window.clear(SF.color(52, 62, 72))

      while @sim_time < @runtime_clock.elapsed_time.as_seconds
        @right_down = SF::Mouse.button_pressed? SF::Mouse::Right

        update()
        @sim_time += 1.0/{% begin %}{{@type.id}}::SIM_FPS{% end %}

        @right_click = false
      end

      draw()

      @text.string = "Use the mouse to grab objects.\n" + @message
      @window.draw @text

      @window.display()
    end
  end

  def update
    @space.step(1.0/{% begin %}{{@type.id}}::SIM_FPS{% end %})
  end

  def draw
    @draw.draw @space
  end

  def draw_bb(bb : CP::BB, color : Color)
    verts = Slice[
      CP.v(bb.right, bb.bottom),
      CP.v(bb.right, bb.top),
      CP.v(bb.left, bb.top),
      CP.v(bb.left, bb.bottom),
    ]
    draw_polygon(verts, 0.0, color, Color.gray(0.0, 0.0))
  end
end
