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

    @circle = SF::CircleShape.new
    @line = SF::VertexArray.new(SF::Lines, 2)
    @polygon = RoundedPolygon.new
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
    @circle.outline_thickness = @scale * 1.25
    @polygon.outline_thickness = @scale * 1.25
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
    @polygon.assign({a, b}, radius)
    @polygon.outline_color = c(outline_color)
    @polygon.fill_color = c(fill_color)

    @target.draw @polygon, @states
  end

  def draw_polygon(verts : Slice(CP::Vect), radius : Float64, outline_color : Color, fill_color : Color)
    @polygon.assign(verts, radius)
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

  class RoundedPolygon < SF::Shape
    def initialize
      super()

      @result = [] of SF::Vector2f
    end

    def assign(points, radius : Number)
      @result.clear

      unless points.size < 2
        p1 = points[points.size - 1]
        v = p1 - points[points.size - 2]
        a1 = Math.atan2(-v.x, v.y)

        points.each do |p2|
          v = p2 - p1
          a2 = Math.atan2(-v.x, v.y)  # normal angle

          a2 += Math::PI * 2 if a2 < a1
          steps = (radius == 0 ? 1 : ((a2 - a1) * 4).round.to_i)
          (0..steps).each do |i|
            a = a2 * i / steps + a1 * (steps - i) / steps
            @result << SF.vector2f(p1.x + Math.cos(a)*radius, p1.y + Math.sin(a)*radius)
          end

          a1 = a2
          p1 = p2
        end
      end

      update()
    end

    def point_count : Int32
      @result.size
    end
    def get_point(index : Int) : SF::Vector2f
      @result[index]
    end
  end
end
