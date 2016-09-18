require "./chipmunk"
require "crsfml"

private macro v(v)
  { {{v}}.x, {{v}}.y }
end

private macro c(c)
  SF::Color.new(
    {% for comp in %w[r g b a] %}
      ({{c}}.{{comp.id}} * 255).to_u8,
    {% end %}
  )
end

class SFMLDebugDraw < CP::Space::DebugDraw
  def initialize(@target : SF::RenderTarget, @states : SF::RenderStates = SF::RenderStates::Default)
    super()

    @circle = SF::CircleShape.new(15.0)
    @fat = RoundEndedLine.new
    @line = SF::VertexArray.new(SF::Lines, 2)
    @polygon = SF::ConvexShape.new
    @dot = SF::CircleShape.new

    @scale = 1f32
    update
  end

  @scale : Float32

  getter states : SF::RenderStates
  def states=(@states : SF::RenderStates)
    update
  end

  def update
    scale = @states.transform.transform_rect(SF.float_rect(0, 0, 1, 1))
    @scale = -2 / (scale.width + scale.height)
    @circle.outline_thickness = @scale
    @fat.outline_thickness = @scale
    @polygon.outline_thickness = @scale
  end

  def draw_circle(pos : CP::Vect, angle : Float64, radius : Float64, outline_color : Color, fill_color : Color)
    @circle.position = v(pos)
    @circle.radius = radius
    @circle.origin = {radius, radius}
    @circle.outline_color = c(outline_color)
    @circle.fill_color = c(fill_color)

    @target.draw @circle, @states
    draw_segment(pos, pos + CP::Vect.angle(angle) * radius, outline_color)
  end

  def draw_segment(a : CP::Vect, b : CP::Vect, color : Color)
    @line[0] = SF::Vertex.new(v(a), c(color))
    @line[1] = SF::Vertex.new(v(b), c(color))

    @target.draw @line, @states
  end

  def draw_fat_segment(a : CP::Vect, b : CP::Vect, radius : Float64, outline_color : Color, fill_color : Color)
    @fat.a = v(a)
    @fat.b = v(b)
    @fat.radius = radius
    @fat.outline_color = c(outline_color)
    @fat.fill_color = c(fill_color)

    @target.draw @fat, @states
  end

  def draw_polygon(verts : Slice(CP::Vect), radius : Float64, outline_color : Color, fill_color : Color)
    @polygon.point_count = verts.size
    verts.each_with_index do |vert, i|
      @polygon[i] = v(vert)
    end
    @polygon.outline_color = c(outline_color)
    @polygon.fill_color = c(fill_color)

    @target.draw @polygon, @states
  end

  def draw_dot(size : Float64, pos : CP::Vect, color : Color)
    radius = size * @scale / 2
    @dot.radius = radius
    @dot.origin = {radius, radius}
    @dot.position = v(pos)
    @dot.fill_color = c(color)

    @target.draw @dot, @states
  end

  class RoundEndedLine < SF::Shape
    # Class written by Foaly
    # https://github.com/SFML/SFML/wiki/Source:-Round-Ended-Lines

    def initialize(a = SF.vector2f(0, 0), b = SF.vector2f(0, 0), radius : Number = 0.5)
      super()

      @a = SF.vector2f(a[0], a[1])
      @b = SF.vector2f(b[0], b[1])
      @radius = radius.to_f32
      update()
    end

    getter a : SF::Vector2f
    def a=(a)
      @a = SF.vector2f(a[0], a[1])
      update()
    end

    getter b : SF::Vector2f
    def b=(b)
      @b = SF.vector2f(b[0], b[1])
      update()
    end

    getter radius : Float32
    def radius=(radius : Number)
      @radius = radius.to_f32
      update()
    end

    def point_count
      30
    end

    def get_point(index)
      if index < 15
        offset = @b
        flip = 1
      else
        offset = @a
        flip = -1
        index -= 15
      end

      start = -Math.atan2(@a.y - @b.y, @b.x - @a.x)
      angle = index * Math::PI / 14 - Math::PI / 2 + start
      offset + SF.vector2f(Math.cos(angle), Math.sin(angle)) * @radius * flip
    end
  end
end
