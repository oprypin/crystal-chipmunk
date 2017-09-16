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


# This file defines a number of "unsafe" operations on Chipmunk objects.
# In this case "unsafe" is referring to operations which may reduce the
# physical accuracy or numerical stability of the simulation, but will not
# cause crashes.
#
# The prime example is mutating collision shapes. Chipmunk does not support
# this directly. Mutating shapes using this API will caused objects in contact
# to be pushed apart using Chipmunk's overlap solver, but not using real
# persistent velocities. Probably not what you meant, but perhaps close enough.

require "./lib"
require "./shape"

module CP
  class Shape::Circle < Shape
    # **Unsafe.** Set the radius of a circle shape.
    #
    # This change is only picked up as a change to the position
    # of the shape's surface, but not its velocity. Changing it will
    # not result in realistic physical behavior. Only use if you know
    # what you are doing!
    def radius=(radius : Number)
      LibCP.circle_shape_set_radius(self, radius)
    end

    # **Unsafe.** Set the offset of a circle shape.
    #
    # This change is only picked up as a change to the position
    # of the shape's surface, but not its velocity. Changing it will
    # not result in realistic physical behavior. Only use if you know
    # what you are doing!
    def offset=(offset : Vect)
      LibCP.circle_shape_set_offset(self, offset)
    end
  end

  class Shape::Segment < Shape
    # **Unsafe.** Set the endpoints of a segment shape.
    #
    # This change is only picked up as a change to the position
    # of the shape's surface, but not its velocity. Changing it will
    # not result in realistic physical behavior. Only use if you know
    # what you are doing!
    def set_endpoints(a : Vect, b : Vect)
      LibCP.segment_shape_set_endpoints(self, a, b)
    end

    # **Unsafe.** Set the radius of a segment shape.
    #
    # This change is only picked up as a change to the position
    # of the shape's surface, but not its velocity. Changing it will
    # not result in realistic physical behavior. Only use if you know
    # what you are doing!
    def radius=(radius : Number)
      LibCP.segment_shape_set_radius(self, radius)
    end
  end

  class Shape::Poly < Shape
    # **Unsafe.** Set the vertices of a poly shape.
    #
    # This change is only picked up as a change to the position
    # of the shape's surface, but not its velocity. Changing it will
    # not result in realistic physical behavior. Only use if you know
    # what you are doing!
    def set_verts(verts : Array(Vect)|Slice(Vect), transform : Transform = Transform::IDENTITY)
      LibCP.poly_shape_set_verts(self, verts.size, verts, transform)
    end

    # **Unsafe.** Set the radius of a poly shape.
    #
    # This change is only picked up as a change to the position
    # of the shape's surface, but not its velocity. Changing it will
    # not result in realistic physical behavior. Only use if you know
    # what you are doing!
    def radius=(radius : Number)
      LibCP.poly_shape_set_radius(self, radius)
    end
  end
end
