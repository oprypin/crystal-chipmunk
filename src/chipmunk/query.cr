# Copyright (c) 2013 Scott Lembcke and Howling Moon Software
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


require "./util"

module CP
  @[Extern]
  # Holds the result of a point query made on a `Shape` or `Space`.
  struct PointQueryInfo
    @shape : LibCP::Shape*
    # The closest point on the shape's surface (in world space coordinates).
    getter point : Vect
    setter point : Vect
    # The distance to the point (negative if the point is inside the shape).
    getter distance : Float64
    setter distance : Float64
    # The gradient of the signed distance function.
    #
    # The value should be similar to `point/distance`, but accurate even for very small values of `distance`.
    getter gradient : Vect
    setter gradient : Vect

    def initialize(shape : Shape, @point : Vect, @distance : Float64, @gradient : Vect)
      @shape = shape.to_unsafe
    end

    # The nearest shape
    def shape : Shape
      Shape[@shape]
    end
    def shape=(shape : Shape)
      @shape = shape.to_unsafe
    end
    # :nodoc:
    def shape=(@shape : LibCP::Shape*)
    end
  end

  @[Extern]
  # Segment queries return more information than just a simple yes or no,
  # they also return where a shape was hit and its surface normal at the hit
  # point. This object holds that information.
  #
  # Segment queries are like ray casting, but because not all spatial indexes
  # allow processing infinitely long ray queries it is limited to segments.
  # In practice this is still very fast and you don't need to worry too much
  # about the performance as long as you aren't using extremely long segments
  # for your queries.
  struct SegmentQueryInfo
    @shape : LibCP::Shape*
    # The point of impact.
    getter point : Vect
    setter point : Vect
    # The normal of the surface hit.
    getter normal : Vect
    setter normal : Vect
    # The normalized distance along the query segment in the range [0, 1].
    getter alpha : Float64
    setter alpha : Float64

    def initialize(shape : Shape, @point : Vect, @normal : Vect, @alpha : Float64)
      @shape = shape.to_unsafe
    end

    # The shape that was hit.
    def shape : Shape
      Shape[@shape]
    end
    def shape=(shape : Shape)
      @shape = shape.to_unsafe
    end
  end

  @[Extern]
  # Fast collision filtering type that is used to determine if two objects collide before calling
  # collision or query callbacks.
  #
  # Chipmunk has two primary means of ignoring collisions: groups and
  # category masks.
  #
  # Groups are used to ignore collisions between parts on a complex object. A
  # ragdoll is a good example. When jointing an arm onto the torso, you'll
  # want them to allow them to overlap. Groups allow you to do exactly that.
  # Shapes that have the same group don't generate collisions. So by placing
  # all of the shapes in a ragdoll in the same group, you'll prevent it from
  # colliding against other parts of itself.
  #
  # Category masks allow you to mark which categories an object belongs to
  # and which categories it collidies with. By default, objects exist in
  # every category and collide with every category.
  #
  # The type of categories and mask in `ShapeFilter` is `UInt32`.
  #
  # There is one last way of filtering collisions using collision handlers.
  # See the section on callbacks for more information. Collision handlers can
  # be more flexible, but can be slower. Fast collision filtering rejects
  # collisions before running the expensive collision detection code, so
  # using groups or category masks is preferred.
  struct ShapeFilter
    alias Group = LibC::SizeT
    alias Bitmask = UInt32

    # Value signifying that a shape is in no group.
    NO_GROUP = Group.new(0)

    # Value for signifying that a shape is in every category.
    ALL_CATEGORIES = ~Bitmask.new(0)

    # Collision filter value for a shape that will collide with anything except `NONE`.
    ALL = new(NO_GROUP, ALL_CATEGORIES, ALL_CATEGORIES)
    # Collision filter value for a shape that does not collide with anything.
    NONE = new(NO_GROUP, ~ALL_CATEGORIES, ~ALL_CATEGORIES)

    # Two objects with the same non-zero group value do not collide.
    #
    # This is generally used to group objects in a composite object together to disable self collisions.
    getter group : Group
    setter group : Group
    # A bitmask of user definable categories that this object belongs to.
    #
    # The category/mask combinations of both objects in a collision must agree for a collision to occur.
    getter categories : Bitmask
    setter categories : Bitmask
    # A bitmask of user definable category types that this object object collides with.
    #
    # The category/mask combinations of both objects in a collision must agree for a collision to occur.
    getter mask : Bitmask
    setter mask : Bitmask

    def initialize(group : Int = NO_GROUP, categories : Int = ALL_CATEGORIES, mask : Int = ALL_CATEGORIES)
      @group = Group.new(group)
      @categories = Bitmask.new(categories)
      @mask = Bitmask.new(mask)
    end
  end
end
