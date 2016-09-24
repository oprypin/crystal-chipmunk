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
    property point : Vect
    property distance : Float64
    property gradient : Vect

    def initialize(shape : Shape, @point : Vect, @distance : Float64, @gradient : Vect)
      @shape = shape.to_unsafe
    end

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
    property point : Vect
    property normal : Vect
    property alpha : Float64

    def initialize(shape : Shape, @point : Vect, @normal : Vect, @alpha : Float64)
      @shape = shape.to_unsafe
    end

    def shape : Shape
      Shape[@shape]
    end
    def shape=(shape : Shape)
      @shape = shape.to_unsafe
    end
  end

  @[Extern]
  struct ShapeFilter
    alias Group = LibC::SizeT
    alias Bitmask = UInt32

    NO_GROUP = Group.new(0)

    ALL_CATEGORIES = ~Bitmask.new(0)

    ALL = new(NO_GROUP, ALL_CATEGORIES, ALL_CATEGORIES)
    NONE = new(NO_GROUP, ~ALL_CATEGORIES, ~ALL_CATEGORIES)

    property group : Group
    property categories : Bitmask
    property mask : Bitmask

    def initialize(group : Int = NO_GROUP, categories : Int = ALL_CATEGORIES, mask : Int = ALL_CATEGORIES)
      @group = Group.new(group)
      @categories = Bitmask.new(categories)
      @mask = Bitmask.new(mask)
    end
  end
end
