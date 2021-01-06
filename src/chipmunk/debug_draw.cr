# Copyright (c) 2007, 2013 Scott Lembcke and Howling Moon Software
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


module CP
  class Space
    abstract class DebugDraw
      # Outline color passed to the drawing function.
      SHAPE_OUTLINE_COLOR = Color.new(*{200, 210, 230}.map(&./ 255.0))
      # Color passed to drawing functions for constraints.
      CONSTRAINT_COLOR = Color.new(0.0, 0.75, 0.0)
      # Color passed to drawing functions for collision points.
      COLLISION_POINT_COLOR = Color.new(1.0, 0.0, 0.0)

      @@spring_verts : Array(CP::Vect) = [
        {0.00, 0.0},
        {0.20, 0.0},
        {0.25, 3.0},
        {0.30,-6.0},
        {0.35, 6.0},
        {0.40,-6.0},
        {0.45, 6.0},
        {0.50,-6.0},
        {0.55, 6.0},
        {0.60,-6.0},
        {0.65, 6.0},
        {0.70,-3.0},
        {0.75, 6.0},
        {0.80, 0.0},
        {1.00, 0.0},
      ].map { |v| CP.v(*v) }

      # Flags that request which things to draw (collision shapes, constraints, contact points).
      @[Flags]
      enum Flags
        DRAW_SHAPES = 1 << 0
        DRAW_CONSTRAINTS = 1 << 1
        DRAW_COLLISION_POINTS = 1 << 2
      end
      _cp_extract Flags

      @[Extern]
      # Color type to use with the space debug drawing API.
      struct Color
        property r : Float32
        property g : Float32
        property b : Float32
        property a : Float32

        def initialize(r : Float, g : Float, b : Float, a : Float = 1.0f32)
          @r = r.to_f32
          @g = g.to_f32
          @b = b.to_f32
          @a = a.to_f32
        end

        def self.gray(l : Float, a : Float = 1.0f32) : self
          new(l, l, l, a)
        end
      end

      def initialize(@flags = Flags::All)
      end

      property flags : Flags

      # Debug draw the current state of the space.
      def draw(space : Space)
        if @flags.draw_shapes?
          space.each_shape do |shape|
            body = shape.body
            next unless body

            fill_color = color_for_shape(shape)

            case shape
            when Shape::Circle
              draw_circle(shape.@shape.tc, body.@body.a, shape.radius, SHAPE_OUTLINE_COLOR, fill_color)
            when Shape::Segment
              draw_fat_segment(shape.@shape.ta, shape.@shape.tb, shape.radius, SHAPE_OUTLINE_COLOR, fill_color)
            when Shape::Poly
              count = shape.size
              planes = shape.@shape.planes
              verts = Slice(Vect).new(count) { |i|
                planes[i].v0
              }
              draw_polygon(verts, shape.radius, SHAPE_OUTLINE_COLOR, fill_color)
            end
          end
        end

        if @flags.draw_constraints?
          space.each_constraint do |constraint|
            body_a = constraint.body_a
            body_b = constraint.body_b

            case constraint
            when Constraint::PinJoint
              a = body_a.@body.transform.transform_point(constraint.anchor_a)
              b = body_b.@body.transform.transform_point(constraint.anchor_b)

              draw_dot(5.0, a, CONSTRAINT_COLOR)
              draw_dot(5.0, b, CONSTRAINT_COLOR)
              draw_segment(a, b, CONSTRAINT_COLOR)
            when Constraint::SlideJoint
              a = body_a.@body.transform.transform_point(constraint.anchor_a)
              b = body_b.@body.transform.transform_point(constraint.anchor_b)

              draw_dot(5.0, a, CONSTRAINT_COLOR)
              draw_dot(5.0, b, CONSTRAINT_COLOR)
              draw_segment(a, b, CONSTRAINT_COLOR)
            when Constraint::PivotJoint
              a = body_a.@body.transform.transform_point(constraint.anchor_a)
              b = body_b.@body.transform.transform_point(constraint.anchor_b)

              draw_dot(5.0, a, CONSTRAINT_COLOR)
              draw_dot(5.0, b, CONSTRAINT_COLOR)
            when Constraint::GrooveJoint
              a = body_a.@body.transform.transform_point(constraint.groove_a)
              b = body_a.@body.transform.transform_point(constraint.groove_b)
              c = body_b.@body.transform.transform_point(constraint.anchor_b)

              draw_dot(5.0, c, CONSTRAINT_COLOR)
              draw_segment(a, b, CONSTRAINT_COLOR)
            when Constraint::DampedSpring
              a = body_a.@body.transform.transform_point(constraint.anchor_a)
              b = body_b.@body.transform.transform_point(constraint.anchor_b)

              draw_dot(5.0, a, CONSTRAINT_COLOR)
              draw_dot(5.0, b, CONSTRAINT_COLOR)

              delta = b - a
              cos, sin = delta.x, delta.y
              s = 1.0 / delta.length

              r1 = CP.v(cos, -sin*s)
              r2 = CP.v(sin,  cos*s)

              verts = Slice(Vect).new(@@spring_verts.size) { |i|
                CP.v((@@spring_verts[i].dot r1) + a.x, (@@spring_verts[i].dot r2) + a.y)
              }

              (@@spring_verts.size - 1).times do |i|
                draw_segment(verts[i], verts[i + 1], CONSTRAINT_COLOR)
              end
            end
          end
        end

        if @flags.draw_collision_points?
          arbiters = space.@space.value.arbiters

          arbiters.value.num.times do |i|
            arb = arbiters.value.arr[i].as(LibCP::Arbiter*)
            n = arb.value.n

            arb.value.count.times do |j|
              p1 = arb.value.body_a.value.p + arb.value.contacts[j].r1
              p2 = arb.value.body_b.value.p + arb.value.contacts[j].r2

              d = 2.0
              a = p1 + n * (-d)
              b = p2 + n * d
              draw_segment(a, b, COLLISION_POINT_COLOR)
            end
          end
        end
      end

      # Draw a filled, stroked circle.
      abstract def draw_circle(pos : Vect, angle : Float64, radius : Float64, outline_color : Color, fill_color : Color)

      # Draw a line segment.
      abstract def draw_segment(a : Vect, b : Vect, color : Color)

      # Draw a thick line segment.
      abstract def draw_fat_segment(a : Vect, b : Vect, radius : Float64, outline_color : Color, fill_color : Color)

      # Draw a convex polygon.
      abstract def draw_polygon(verts : Slice(Vect), radius : Float64, outline_color : Color, fill_color : Color)

      # Draw a dot.
      abstract def draw_dot(size : Float64, pos : Vect, color : Color)

      # Returns a color for a given shape.
      #
      # This gives you an opportunity to color shapes based on how they are used in your engine.
      def color_for_shape(shape : Shape) : Color
        return Color.gray(1.0, 0.1) if shape.sensor?

        body = shape.body.not_nil!

        if body.sleeping?
          Color.gray(0.2)
        elsif body.@body.sleeping.idle_time > shape.space.not_nil!.sleep_time_threshold
          Color.gray(0.66)
        else
          hash = shape.to_unsafe.value.hashid

          DebugDraw.color_for_hash(hash, intensity: body.type.static? ? 0.15 : 0.75)
        end
      end

      def self.color_for_hash(hash : Int, intensity : Number) : Color
        val = hash.to_u32!

        # scramble the bits up using Robert Jenkins' 32 bit integer hash function
        val = (val &+ 0x7ed55d16_u32) &+ (val << 12)
        val = (val ^ 0xc761c23c_u32) ^ (val >> 19)
        val = (val &+ 0x165667b1_u32) &+ (val << 5)
        val = (val &+ 0xd3a2646c_u32) ^ (val << 9)
        val = (val &+ 0xfd7046c5_u32) &+ (val << 3)
        val = (val ^ 0xb55a4f09_u32) ^ (val >> 16)

        r = (val >> 0) & 0xFF
        g = (val >> 8) & 0xFF
        b = (val >> 16) & 0xFF

        max = {r, g, b}.max
        min = {r, g, b}.min

        # Saturate and scale the color
        if min == max
          Color.new(intensity, 0.0, 0.0)
        else
          coef = intensity / (max - min)
          Color.new((r - min) * coef, (g - min) * coef, (b - min) * coef)
        end
      end
    end
  end
end
