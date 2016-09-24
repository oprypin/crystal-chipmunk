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
  abstract class Shape
    abstract def to_unsafe : LibCP::Shape

    # :nodoc:
    def self.[](this : LibCP::Shape*) : self
      LibCP.shape_get_user_data(this).as(self)
    end
    # :nodoc:
    def self.[]?(this : LibCP::Shape*) : self?
      self[this] if this
    end

    def finalize
      LibCP.shape_destroy(self)
    end

    def cache_bb() : BB
      LibCP.shape_cache_bb(self)
    end

    def update(transform : Transform) : BB
      LibCP.shape_update(self, transform)
    end

    def point_query(p : Vect) : PointQueryInfo
      LibCP.shape_point_query(self, p, out info)
      info
    end

    def segment_query(a : Vect, b : Vect, radius : Number = 0) : SegmentQueryInfo?
      if LibCP.shape_segment_query(self, a, b, radius, out info)
        info
      end
    end

    def collide(b : Shape) : ContactPointSet
      LibCP.shapes_collide(self, b)
    end

    def space : Space?
      Space[LibCP.shape_get_space(self)]?
    end

    def body : Body?
      Body[LibCP.shape_get_body(self)]?
    end
    def body=(body : Body?)
      LibCP.shape_set_body(self, body)
    end

    def mass : Float64
      LibCP.shape_get_mass(self)
    end
    def mass=(mass : Number)
      LibCP.shape_set_mass(self, mass)
    end

    def density : Float64
      LibCP.shape_get_density(self)
    end
    def density=(density : Number)
      LibCP.shape_set_density(self, density)
    end

    def moment() : Float64
      LibCP.shape_get_moment(self)
    end

    def area() : Float64
      LibCP.shape_get_area(self)
    end

    def center_of_gravity() : Vect
      LibCP.shape_get_center_of_gravity(self)
    end

    def bb() : BB
      LibCP.shape_get_bb(self)
    end

    def sensor? : Bool
      LibCP.shape_get_sensor(self)
    end
    def sensor=(sensor : Bool)
      LibCP.shape_set_sensor(self, sensor)
    end

    def elasticity : Float64
      LibCP.shape_get_elasticity(self)
    end
    def elasticity=(elasticity : Number)
      LibCP.shape_set_elasticity(self, elasticity)
    end

    def friction : Float64
      LibCP.shape_get_friction(self)
    end
    def friction=(friction : Number)
      LibCP.shape_set_friction(self, friction)
    end

    def surface_velocity : Vect
      LibCP.shape_get_surface_velocity(self)
    end
    def surface_velocity=(surface_velocity : Vect)
      LibCP.shape_set_surface_velocity(self, surface_velocity)
    end

    def collision_type : CollisionType
      LibCP.shape_get_collision_type(self)
    end
    def collision_type=(collision_type : Int)
      LibCP.shape_set_collision_type(self, collision_type)
    end

    def filter : ShapeFilter
      LibCP.shape_get_filter(self)
    end
    def filter=(filter : ShapeFilter)
      LibCP.shape_set_filter(self, filter)
    end

    class Circle < Shape
      def self.moment(m : Number, r1 : Number, r2 : Number, offset : Vect = CP::Vect.new(0, 0)) : Float64
        LibCP.moment_for_circle(m, r1, r2, offset)
      end

      def self.area(r1 : Number, r2 : Number) : Float64
        LibCP.area_for_circle(r1, r2)
      end

      def initialize(body : Body?, radius : Number, offset : Vect = CP::Vect.new(0, 0))
        @shape = uninitialized LibCP::CircleShape
        LibCP.circle_shape_init(pointerof(@shape), body, radius, offset)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end

      # :nodoc:
      def to_unsafe : LibCP::Shape*
        pointerof(@shape).as(LibCP::Shape*)
      end

      def offset : Vect
        LibCP.circle_shape_get_offset(self)
      end

      def radius : Float64
        LibCP.circle_shape_get_radius(self)
      end
    end

    class Segment < Shape
      def self.moment(m : Number, a : Vect, b : Vect, radius : Number = 0) : Float64
        LibCP.moment_for_segment(m, a, b, radius)
      end

      def self.area(a : Vect, b : Vect, radius : Number) : Float64
        LibCP.area_for_segment(a, b, radius)
      end

      def initialize(body : Body?, a : Vect, b : Vect, radius : Number = 0)
        @shape = uninitialized LibCP::SegmentShape
        LibCP.segment_shape_init(pointerof(@shape), body, a, b, radius)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end

      # :nodoc:
      def to_unsafe : LibCP::Shape*
        pointerof(@shape).as(LibCP::Shape*)
      end

      def set_neighbors(prev : Vect, next next_ : Vect)
        LibCP.segment_shape_set_neighbors(self, prev, next_)
      end

      def a : Vect
        LibCP.segment_shape_get_a(self)
      end
      def b : Vect
        LibCP.segment_shape_get_b(self)
      end

      def normal() : Vect
        LibCP.segment_shape_get_normal(self)
      end

      def radius : Float64
        LibCP.segment_shape_get_radius(self)
      end
    end

    class Poly < Shape
      def self.moment(m : Number, verts : Array(Vect)|Slice(Vect), offset : Vect = CP::Vect.new(0, 0), radius : Number = 0) : Float64
        LibCP.moment_for_poly(m, verts.size, verts, offset, radius)
      end

      def self.area(verts : Array(Vect)|Slice(Vect), radius : Number = 0) : Float64
        LibCP.area_for_poly(verts.size, verts, radius)
      end

      def self.centroid(verts : Array(Vect)|Slice(Vect)) : Vect
        LibCP.centroid_for_poly(verts.size, verts)
      end

      def self.convex_hull(verts : Array(Vect)|Slice(Vect), tol : Number) : {Slice(Vect), Int32}
        result = Slice(Vect).new(verts.size)
        LibCP.convex_hull(verts.size, verts, result, out first, tol)
        {result, first}
      end

      include Enumerable(Vect)
      include Indexable(Vect)

      def initialize(body : Body?, verts : Array(Vect)|Slice(Vect), transform : Transform = Transform::IDENTITY, radius : Number = 0)
        @shape = uninitialized LibCP::PolyShape
        LibCP.poly_shape_init(pointerof(@shape), body, verts.size, verts, transform, radius)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end
      def initialize(body : Body?, verts : Array(Vect)|Slice(Vect), radius : Number)
        @shape = uninitialized LibCP::PolyShape
        LibCP.poly_shape_init_raw(pointerof(@shape), body, verts.size, verts, radius)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end

      # :nodoc:
      def to_unsafe : LibCP::Shape*
        pointerof(@shape).as(LibCP::Shape*)
      end

      def size : Int32
        LibCP.poly_shape_get_count(self)
      end

      def unsafe_at(index : Int32) : Vect
        LibCP.poly_shape_get_vert(self, index)
      end

      def radius : Float64
        LibCP.poly_shape_get_radius(self)
      end
    end

    class Box < Poly
      def self.moment(m : Number, width : Number, height : Number) : Float64
        LibCP.moment_for_box(m, width, height)
      end

      def self.moment(m : Number, box : BB) : Float64
        LibCP.moment_for_box2(m, box)
      end

      def initialize(body : Body?, width : Number, height : Number, radius : Number = 0)
        @shape = uninitialized LibCP::PolyShape
        LibCP.box_shape_init(pointerof(@shape), body, width, height, radius)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end
      def initialize(body : Body?, box : BB, radius : Number = 0)
        @shape = uninitialized LibCP::PolyShape
        LibCP.box_shape_init2(pointerof(@shape), body, box, radius)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end
    end
  end

  # :nodoc:
  alias Circle = Shape::Circle
  # :nodoc:
  alias Segment = Shape::Segment
  # :nodoc:
  alias Poly = Shape::Poly
  # :nodoc:
  alias Box = Shape::Box
end
