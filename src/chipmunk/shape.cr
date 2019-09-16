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
  # Defines the shape of a rigid body.
  abstract class Shape
    # :nodoc:
    abstract def to_unsafe : LibCP::Shape*

    # :nodoc:
    def self.[](this : LibCP::Shape*) : self
      LibCP.shape_get_user_data(this).as(self)
    end
    # :nodoc:
    def self.[]?(this : LibCP::Shape*) : self?
      self[this] if this
    end

    # Avoid a finalization cycle; cpShapeDestroy is empty for most subclasses
    #def finalize
      #LibCP.shape_destroy(self)
    #end

    # Update, cache and return the bounding box of a shape based on the body it's attached to.
    def cache_bb() : BB
      LibCP.shape_cache_bb(self)
    end

    # Update, cache and return the bounding box of a shape with an explicit transformation.
    #
    # Useful if you have a shape without a body and want to use it for querying.
    def update(transform : Transform) : BB
      LibCP.shape_update(self, transform)
    end

    # Perform a nearest point query. It finds the closest point on the surface of shape to a specific point.
    def point_query(p : Vect) : PointQueryInfo
      LibCP.shape_point_query(self, p, out info)
      info
    end

    # Perform a segment query against a shape: check if the line segment from start to end intersects the shape.
    def segment_query(a : Vect, b : Vect, radius : Number = 0) : SegmentQueryInfo?
      if LibCP.shape_segment_query(self, a, b, radius, out info)
        info
      end
    end

    # Return contact information about two shapes.
    def collide(b : Shape) : ContactPointSet
      LibCP.shapes_collide(self, b)
    end

    # The `Space` this shape is added to.
    def space : Space?
      Space[LibCP.shape_get_space(self)]?
    end

    # The `Body` this shape is added to.
    def body : Body?
      Body[LibCP.shape_get_body(self)]?
    end
    # Set the `Body` this shape is added to.
    #
    # Can only be used if the shape is not currently added to a space.
    def body=(body : Body?)
      LibCP.shape_set_body(self, body)
    end

    # Get the mass of the shape if you are having Chipmunk calculate mass properties for you.
    def mass : Float64
      LibCP.shape_get_mass(self)
    end
    # Set the mass of this shape to have Chipmunk calculate mass properties for you.
    def mass=(mass : Number)
      LibCP.shape_set_mass(self, mass)
    end

    # Get the density of the shape if you are having Chipmunk calculate mass properties for you.
    def density : Float64
      LibCP.shape_get_density(self)
    end
    # Set the density of this shape to have Chipmunk calculate mass properties for you.
    def density=(density : Number)
      LibCP.shape_set_density(self, density)
    end

    # Get the calculated moment of inertia for this shape.
    def moment() : Float64
      LibCP.shape_get_moment(self)
    end

    # Get the calculated area of this shape.
    def area() : Float64
      LibCP.shape_get_area(self)
    end

    # Get the centroid of this shape.
    def center_of_gravity() : Vect
      LibCP.shape_get_center_of_gravity(self)
    end

    # Get the bounding box that contains the shape given its current position and angle.
    #
    # Only guaranteed to be valid after `cache_bb` or `Space#step` is called.
    # Moving a body that a shape is connected to does not update its bounding box.
    # For shapes used for queries that aren't attached to bodies, you can also use `update`.
    def bb() : BB
      LibCP.shape_get_bb(self)
    end

    # Is the shape set to be a sensor or not?
    #
    # Sensors only call collision callbacks, and never generate real collisions.
    def sensor? : Bool
      LibCP.shape_get_sensor(self)
    end
    def sensor=(sensor : Bool)
      LibCP.shape_set_sensor(self, sensor)
    end

    # The elasticity of this shape.
    #
    # A value of 0.0 gives no bounce, while a value of 1.0 will give a
    # 'perfect' bounce. However due to inaccuracies in the simulation
    # using 1.0 or greater is not recommended.
    def elasticity : Float64
      LibCP.shape_get_elasticity(self)
    end
    def elasticity=(elasticity : Number)
      LibCP.shape_set_elasticity(self, elasticity)
    end

    # The friction of this shape.
    #
    # Chipmunk uses the Coulomb friction model, a value of 0.0 is
    # frictionless. A value over 1.0 is also perfectly fine.
    def friction : Float64
      LibCP.shape_get_friction(self)
    end
    def friction=(friction : Number)
      LibCP.shape_set_friction(self, friction)
    end

    # The surface velocity of this shape.
    #
    # Useful for creating conveyor belts or players that move around. This
    # value is only used when calculating friction, not resolving the collision.
    def surface_velocity : Vect
      LibCP.shape_get_surface_velocity(self)
    end
    def surface_velocity=(surface_velocity : Vect)
      LibCP.shape_set_surface_velocity(self, surface_velocity)
    end

    # User defined collision type for the shape.
    #
    # See `Space#add_collision_handler` for more information.
    def collision_type : CollisionType
      LibCP.shape_get_collision_type(self)
    end
    def collision_type=(collision_type : Int)
      LibCP.shape_set_collision_type(self, collision_type)
    end

    # The collision filtering parameters of this shape.
    def filter : ShapeFilter
      LibCP.shape_get_filter(self)
    end
    def filter=(filter : ShapeFilter)
      LibCP.shape_set_filter(self, filter)
    end

    # A circle shape defined by a radius
    #
    # This is the fastest and simplest collision shape
    class Circle < Shape
      # Calculate the moment of inertia for a circle.
      #
      # *r1* and *r2* are the inner and outer diameters. A solid circle has an inner diameter of 0.
      def self.moment(m : Number, r1 : Number, r2 : Number, offset : Vect = CP::Vect.new(0, 0)) : Float64
        LibCP.moment_for_circle(m, r1, r2, offset)
      end

      # Calculate area of a hollow circle.
      #
      # *r1* and *r2* are the inner and outer diameters. A solid circle has an inner diameter of 0.
      def self.area(r1 : Number, r2 : Number) : Float64
        LibCP.area_for_circle(r1, r2)
      end

      # The parameters are: the *body* to attach the circle to; the *offset* from the
      # body's center of gravity in body local coordinates.
      def initialize(body : Body?, radius : Number, offset : Vect = CP::Vect.new(0, 0))
        @shape = uninitialized LibCP::CircleShape
        LibCP.circle_shape_init(pointerof(@shape), body, radius, offset)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end

      # :nodoc:
      def to_unsafe : LibCP::Shape*
        pointerof(@shape).as(LibCP::Shape*)
      end

      # Get the offset of a circle shape.
      def offset : Vect
        LibCP.circle_shape_get_offset(self)
      end

      # Get the radius of a circle shape.
      def radius : Float64
        LibCP.circle_shape_get_radius(self)
      end
    end

    # A line segment shape between two points.
    #
    # Meant mainly as a static shape. Can be beveled in order to give them a thickness.
    class Segment < Shape
      # Calculate the moment of inertia for a line segment.
      #
      # Beveling radius is not supported.
      def self.moment(m : Number, a : Vect, b : Vect, radius : Number = 0) : Float64
        LibCP.moment_for_segment(m, a, b, radius)
      end

      # Calculate the area of a fattened (capsule shaped) line segment.
      def self.area(a : Vect, b : Vect, radius : Number) : Float64
        LibCP.area_for_segment(a, b, radius)
      end

      # The parameters are: the *body* to attach the segment to; the endpoints (*a*, *b*) to attach the segment to;
      # the *radius* of the half-circles at the ends of the segment (thickness is twice the radius).
      def initialize(body : Body?, a : Vect, b : Vect, radius : Number = 0)
        @shape = uninitialized LibCP::SegmentShape
        LibCP.segment_shape_init(pointerof(@shape), body, a, b, radius)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end

      # :nodoc:
      def to_unsafe : LibCP::Shape*
        pointerof(@shape).as(LibCP::Shape*)
      end

      # Let Chipmunk know about the geometry of adjacent segments to avoid colliding with endcaps.
      #
      # When you have a number of segment shapes that are all joined
      # together, things can still collide with the "cracks" between the
      # segments. By setting the neighbor segment endpoints you can tell
      # Chipmunk to avoid colliding with the inner parts of the crack.
      def set_neighbors(prev : Vect, next next_ : Vect)
        LibCP.segment_shape_set_neighbors(self, prev, next_)
      end

      # Get the first endpoint of a segment shape.
      def a : Vect
        LibCP.segment_shape_get_a(self)
      end
      # Get the second endpoint of a segment shape.
      def b : Vect
        LibCP.segment_shape_get_b(self)
      end

      # Get the normal of a segment shape.
      def normal() : Vect
        LibCP.segment_shape_get_normal(self)
      end

      # Get the radius of a segment shape.
      def radius : Float64
        LibCP.segment_shape_get_radius(self)
      end
    end

    # A convex polygon shape
    #
    # Slowest, but most flexible collision shape.
    class Poly < Shape
      # Calculate the moment of inertia for a solid polygon shape.
      #
      # Assumes its center of gravity is at its centroid. The offset is added to each vertex.
      def self.moment(m : Number, verts : Array(Vect)|Slice(Vect), offset : Vect = CP::Vect.new(0, 0), radius : Number = 0) : Float64
        LibCP.moment_for_poly(m, verts.size, verts, offset, radius)
      end

      # Calculate the signed area of a polygon.
      #
      # A clockwise winding gives positive area.
      # This is probably backwards from what you expect, but matches Chipmunk's winding for poly shapes.
      def self.area(verts : Array(Vect)|Slice(Vect), radius : Number = 0) : Float64
        LibCP.area_for_poly(verts.size, verts, radius)
      end

      # Calculate the natural centroid of a polygon.
      def self.centroid(verts : Array(Vect)|Slice(Vect)) : Vect
        LibCP.centroid_for_poly(verts.size, verts)
      end

      # Calculate the convex hull of a given set of points.
      #
      # *tol* is the allowed amount to shrink the hull when simplifying it.
      # A tolerance of 0.0 creates an exact hull.
      #
      # Returns the convex hull and the index where the first vertex
      # in the hull came from (i.e. `verts[first] == result[0]`)
      def self.convex_hull(verts : Array(Vect)|Slice(Vect), tol : Number = 0) : {Slice(Vect), Int32}
        result = Slice(Vect).new(verts.size)
        LibCP.convex_hull(verts.size, verts, result, out first, tol)
        {result, first}
      end

      include Enumerable(Vect)
      include Indexable(Vect)

      # Initialize a polygon shape with rounded corners.
      # A convex hull will be created from the vertices.
      #
      # The parameters are: the *body* to attach the poly to; the *verts* (vertices) of the polygon;
      # the *transform* to apply to every vertex; the radius of the corners.
      #
      # Adding a small radius will bevel the corners and can significantly reduce problems
      # where the poly gets stuck on seams in your geometry.
      def initialize(body : Body?, verts : Array(Vect)|Slice(Vect), transform : Transform = Transform::IDENTITY, radius : Number = 0)
        @shape = uninitialized LibCP::PolyShape
        LibCP.poly_shape_init(pointerof(@shape), body, verts.size, verts, transform, radius)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end
      # Initialize a polygon shape with rounded corners.
      # The vertices must be convex with a counter-clockwise winding.
      def initialize(body : Body?, verts : Array(Vect)|Slice(Vect), radius : Number)
        @shape = uninitialized LibCP::PolyShape
        LibCP.poly_shape_init_raw(pointerof(@shape), body, verts.size, verts, radius)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end

      # :nodoc:
      def to_unsafe : LibCP::Shape*
        pointerof(@shape).as(LibCP::Shape*)
      end

      # Better leak a small array than cause a finalization cycle...
      #def finalize
        #LibCP.shape_destroy(self)
      #end

      # Get the number of verts in a polygon shape.
      def size : Int32
        LibCP.poly_shape_get_count(self)
      end

      # Get the *i*-th vertex of a polygon shape.
      def unsafe_fetch(index : Int) : Vect
        LibCP.poly_shape_get_vert(self, index.to_i32)
      end
      # :nodoc:
      def unsafe_at(index : Int32) : Vect
        LibCP.poly_shape_get_vert(self, index)
      end

      # Get the radius of a polygon shape.
      def radius : Float64
        LibCP.poly_shape_get_radius(self)
      end
    end

    # A special case of a polygon - a rectangle.
    #
    # The boxes will always be centered at the center of gravity of the
    # body you are attaching them to. If you want to create an off-center
    # box, you will need to use `Poly`.
    class Box < Poly
      # Calculate the moment of inertia for a solid box.
      def self.moment(m : Number, width : Number, height : Number) : Float64
        LibCP.moment_for_box(m, width, height)
      end

      # Calculate the moment of inertia for a solid box.
      def self.moment(m : Number, box : BB) : Float64
        LibCP.moment_for_box2(m, box)
      end

      # Initialize a box shaped polygon shape with rounded corners.
      def initialize(body : Body?, width : Number, height : Number, radius : Number = 0)
        @shape = uninitialized LibCP::PolyShape
        LibCP.box_shape_init(pointerof(@shape), body, width, height, radius)
        LibCP.shape_set_user_data(self, self.as(Void*))
      end
      # Initialize an offset box shaped polygon shape with rounded corners.
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
