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
  struct PointQueryInfo
    @shape : LibCP::Shape*
    # The closest point on the shape's surface (in world space coordinates).
    property point : Vect
    # The distance to the point. The distance is negative if the point is inside the shape.
    property distance : Float64
    # The gradient of the signed distance function.
    #
    # The value should be similar to info.p/info.d, but accurate even for very small values of info.d.
    property gradient : Vect

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
  struct SegmentQueryInfo
    @shape : LibCP::Shape*
    # The point of impact.
    property point : Vect
    # The normal of the surface hit.
    property normal : Vect
    # The normalized distance along the query segment in the range [0, 1].
    property alpha : Float64

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
  # Fast collision filtering type that is used to determine if two objects collide before calling collision or query callbacks.
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
    property group : Group
    # A bitmask of user definable categories that this object belongs to.
    #
    # The category/mask combinations of both objects in a collision must agree for a collision to occur.
    property categories : Bitmask
    # A bitmask of user definable category types that this object object collides with.
    #
    # The category/mask combinations of both objects in a collision must agree for a collision to occur.
    property mask : Bitmask

    def initialize(group : Int = NO_GROUP, categories : Int = ALL_CATEGORIES, mask : Int = ALL_CATEGORIES)
      @group = Group.new(group)
      @categories = Bitmask.new(categories)
      @mask = Bitmask.new(mask)
    end
  end
end
