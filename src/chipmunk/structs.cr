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


module CP
  extend self

  @[Extern]
  struct Vect
    property x : Float64, y : Float64

    def initialize(x : Number, y : Number)
      @x = x.to_f
      @y = y.to_f
    end

    def self.angle(a : Number) : self
      Vect.new(Math.cos(a), Math.sin(a))
    end

    def ==(v2 : Vect) : Bool
      @x == v2.x && @y == v2.y
    end

    def +(v2 : Vect) : Vect
      Vect.new(@x + v2.x, @y + v2.y)
    end

    def -(v2 : Vect) : Vect
      Vect.new(@x - v2.x, @y - v2.y)
    end

    def -() : Vect
      Vect.new(-@x, -@y)
    end

    def *(s : Number) : Vect
      Vect.new(@x * s, @y * s)
    end

    def dot(v2 : Vect) : Float64
      @x * v2.x + @y * v2.y
    end

    def cross(v2 : Vect) : Float64
      @x * v2.y - @y * v2.x
    end

    def perp() : Vect
      Vect.new(-@y, @x)
    end

    def rperp() : Vect
      Vect.new(@y, -@x)
    end

    def project(v2 : Vect) : Vect
      v2 * (dot v2) / (v2.dot v2)
    end

    def to_angle() : Float64
      Math.atan2(@y, @x)
    end

    def rotate(v2 : Vect) : Vect
      Vect.new(@x * v2.x - @y * v2.y, @x * v2.y + @y * v2.x)
    end

    def unrotate(v2 : Vect) : Vect
      Vect.new(@x * v2.x + @y * v2.y, @y * v2.x - @x * v2.y)
    end

    def lengthsq() : Float64
      dot(self)
    end

    def length() : Float64
      Math.sqrt(dot(self))
    end

    def self.lerp(v1 : Vect, v2 : Vect, t : Number) : Vect
      (v1 * (1.0 - t)) + (v2 * t)
    end

    def normalize() : Vect
      self * (1.0 / (length + 2.2250738585072014e-308))
    end

    def self.slerp(v1 : Vect, v2 : Vect, t : Number) : Vect
      dot = v1.normalize.dot v2.normalize
      omega = Math.acos(dot.clamp(-1.0, 1.0))
      if omega < 1e-3
        Vect.lerp(v1, v2, t)
      else
        denom = 1.0 / Math.sin(omega)
        v1 * (Math.sin((1.0 - t) * omega) * denom) + v2 * (Math.sin(t * omega) * denom)
      end
    end

    def self.slerpconst(v1 : Vect, v2 : Vect, a : Number) : Vect
      dot = v1.normalize.dot v2.normalize
      omega = Math.acos(dot.clamp(-1.0, 1.0))
      self.slerp(v1, v2, {a, omega}.min / omega)
    end

    def clamp(len : Number) : Vect
      dot(self) > len*len ? normalize*len : self
    end

    def self.lerpconst(v1 : Vect, v2 : Vect, d : Number) : Vect
      v1 + (v2 - v1).clamp(d)
    end

    def self.dist(v1 : Vect, v2 : Vect) : Float64
      (v1 - v2).length
    end

    def self.distsq(v1 : Vect, v2 : Vect) : Float64
      (v1 - v2).lengthsq
    end

    def self.near(v1 : Vect, v2 : Vect, dist : Number) : Bool
      Vect.distsq(v1, v2) < dist*dist
    end

    def closest_point_on_segment(a : Vect, b : Vect) : Vect
      delta = a - b
      t = (delta.dot(self - b) / delta.lengthsq).clamp(0.0, 1.0)
      b + delta*t
    end
  end

  def v(x, y)
    Vect.new(x, y)
  end

  def vzero()
    Vect.new(0.0, 0.0)
  end

  @[Extern]
  struct Transform
    IDENTITY = new

    property a : Float64, b : Float64, c : Float64, d : Float64
    property tx : Float64, ty : Float64

    def initialize(a : Number = 1, b : Number = 0, c : Number = 0, d : Number = 1, tx : Number = 0, ty : Number = 0)
      @a = a.to_f
      @b = b.to_f
      @c = c.to_f
      @d = d.to_f
      @tx = tx.to_f
      @ty = ty.to_f
    end

    def self.new_transpose(a : Number, c : Number, tx : Number, b : Number, d : Number, ty : Number) : self
      Transform.new(a, b, c, d, tx, ty)
    end

    def inverse() : Transform
      inv_det = 1.0 / (@a*@d - @c*@b)
      Transform.new_transpose(
         @d*inv_det, -@c*inv_det, (@c*@ty - @tx*@d)*inv_det,
        -@b*inv_det,  @a*inv_det, (@tx*@b - @a*@ty)*inv_det
      )
    end

    def *(t2 : Transform) : Transform
      Transform.new_transpose(
        @a*t2.a + @c*t2.bottom, @a*t2.c + @c*t2.d, @a*t2.tx + @c*t2.ty + @tx,
        @b*t2.a + @d*t2.bottom, @b*t2.c + @d*t2.d, @b*t2.tx + @d*t2.ty + @ty
      )
    end

    def transform_point(p : Vect) : Vect
      Vect.new(@a*p.x + @c*p.y + @tx, @b*p.x + @d*p.y + @ty)
    end

    def transform_vect(v : Vect) : Vect
      Vect.new((@a * v.x) + (@c * v.y), (@b * v.x) + (@d * v.y))
    end

    def transform(bb : BB) : BB
      center = bb.center
      hw = (bb.right - bb.left) * 0.5
      hh = (bb.top - bb.bottom) * 0.5
      a = @a * hw
      b = @c * hh
      d = @b * hw
      e = @d * hh
      hw_max = {(a + b).abs, (a - b).abs}.max
      hh_max = {(d + e).abs, (d - e).abs}.max
      Transform.new_for_extents(transform_point(center), hw_max, hh_max)
    end

    def self.translate(translate : Vect) : self
      Transform.new_transpose(1.0, 0.0, translate.x, 0.0, 1.0, translate.y)
    end

    def self.scale(scale_x : Number, scale_y : Number) : self
      Transform.new_transpose(scale_x, 0.0, 0.0, 0.0, scale_y, 0.0)
    end

    def self.rotate(radians : Number) : self
      rot = Vect.angle(radians)
      Transform.new_transpose(rot.x, -rot.y, 0.0, rot.y, rot.x, 0.0)
    end

    def rigid(translate : Vect, radians : Number) : Transform
      rot = Vect.angle(radians)
      Transform.new_transpose(rot.x, -rot.y, translate.x, rot.y, rot.x, translate.y)
    end

    def rigid_inverse() : Transform
      Transform.new_transpose(
         @d, -@c, (@c*@ty - @tx*@d),
        -@b,  @a, (@tx*@b - @a*@ty)
      )
    end

    def wrap(inner : Transform) : Transform
      inverse * (inner * self)
    end

    def wrap_inverse(inner : Transform) : Transform
      self * (inner * inverse)
    end

    def self.ortho(bb : BB) : self
      Transform.new_transpose(
        2.0/(bb.right - bb.left), 0.0, -(bb.right + bb.left)/(bb.right - bb.left),
        0.0, 2.0/(bb.top - bb.bottom), -(bb.top + bb.bottom)/(bb.top - bb.bottom)
      )
    end

    def self.bone_scale(v0 : Vect, v1 : Vect) : self
      d = v1 - v0
      transform_new_transpose(d.x, -d.y, v0.x, d.y, d.x, v0.y)
    end

    def self.axial_scale(axis : Vect, pivot : Vect, scale : Number) : self
      a = axis.x * axis.y * (scale - 1.0)
      b = axis.dot(pivot) * (1.0 - scale)
      Transform.new_transpose(
        scale*axis.x*axis.x + axis.y*axis.y, a, axis.x*b,
        a, axis.x*axis.x + scale*axis.y*axis.y, axis.y*b
      )
    end
  end

  @[Extern]
  struct Mat2x2
    property a : Float64, b : Float64, c : Float64, d : Float64

    def initialize(a : Number, b : Number, c : Number, d : Number)
      @a = a.to_f
      @b = b.to_f
      @c = c.to_f
      @d = d.to_f
    end

    def transform(v : Vect) : Vect
      Vect.new((v.x * @a) + (v.y * @b), (v.x * @c) + (v.y * @d))
    end
  end

  @[Extern]
  struct BB
    property left : Float64, bottom : Float64, right : Float64, top : Float64

    def initialize(left : Number = 0, bottom : Number = 0, right : Number = 0, top : Number = 0)
      @left = left.to_f
      @bottom = bottom.to_f
      @right = right.to_f
      @top = top.to_f
    end

    def self.new_for_extents(c : Vect, hw : Number, hh : Number) : self
      BB.new(c.x - hw, c.y - hh, c.x + hw, c.y + hh)
    end

    def self.new_for_circle(p : Vect, r : Number) : self
      BB.new_for_extents(p, r, r)
    end

    def intersects?(other : BB) : Bool
      @left <= other.right && other.left <= @right && @bottom <= other.top && other.bottom <= @top
    end

    def contains?(other : BB) : Bool
      @left <= other.left && @right >= other.right && @bottom <= other.bottom && @top >= other.top
    end

    def contains?(v : Vect) : Bool
      @left <= v.x && @right >= v.x && @bottom <= v.y && @top >= v.y
    end

    def merge(b : BB) : BB
      BB.new({@left, b.left}.min, {@bottom, b.bottom}.min, {@right, b.right}.max, {@top, b.top}.max)
    end

    def expand(v : Vect) : BB
      BB.new({@left, v.x}.min, {@bottom, v.y}.min, {@right, v.x}.max, {@top, v.y}.max)
    end

    def center() : Vect
      Vect.lerp(Vect.new(@left, @bottom), Vect.new(@right, @top), 0.5)
    end

    def area() : Float64
      (@right - @left) * (@top - @bottom)
    end

    def merged_area(b : BB) : Float64
      ({@right, b.right}.max - {@left, b.left}.min) * ({@top, b.top}.max - {@bottom, b.bottom}.min)
    end

    def segment_query(a : Vect, b : Vect) : Float64
      idx = 1.0 / (b.x - a.x)
      tx1 = @left == a.x ? Float64::MIN : (@left - a.x) * idx
      tx2 = @right == a.x ? Float64::MAX : (@right - a.x) * idx
      txmin = {tx1, tx2}.min
      txmax = {tx1, tx2}.max
      idy = 1.0 / (b.y - a.y)
      ty1 = @bottom == a.y ? Float64::MIN : (@bottom - a.y) * idy
      ty2 = @top == a.y ? Float64::MAX : (@top - a.y) * idy
      tymin = {ty1, ty2}.min
      tymax = {ty1, ty2}.max
      if tymin <= txmax && txmin <= tymax
        min = {txmin, tymin}.max
        max = {txmax, tymax}.min
        if 0.0 <= max && min <= 1.0
          return {min, 0.0}.max
        end
      end
      Float64::MAX
    end

    def intersects_segment?(a : Vect, b : Vect) : Bool
      segment_query(a, b) != Float64::MAX
    end

    def clamp_vect(v : Vect) : Vect
      Vect.new(v.x.clamp(@left, @right), v.y.clamp(@bottom, @top))
    end

    def wrap_vect(v : Vect) : Vect
      dx = (@right - @left).abs
      modx = (v.x - @left).fdiv(dx)
      x = modx > 0.0 ? modx : modx + dx
      dy = (@top - @bottom).abs
      mody = (v.y - @bottom).fdiv(dy)
      y = mody > 0.0 ? mody : mody + dy
      Vect.new(x + @left, y + @bottom)
    end

    def offset(v : Vect) : BB
      BB.new(@left + v.x, @bottom + v.y, @right + v.x, @top + v.y)
    end
  end

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
    property group : Group
    property categories : Bitmask
    property mask : Bitmask

    def initialize(group : Int = NO_GROUP, categories : Int = ALL_CATEGORIES, mask : Int = ALL_CATEGORIES)
      @group = Group.new(group)
      @categories = Bitmask.new(categories)
      @mask = Bitmask.new(mask)
    end

    ALL = new(NO_GROUP, ALL_CATEGORIES, ALL_CATEGORIES)
    NONE = new(NO_GROUP, ~ALL_CATEGORIES, ~ALL_CATEGORIES)
  end

  alias CollisionID = UInt32
  alias CollisionType = LibC::SizeT
  alias Group = LibC::SizeT
  alias Bitmask = UInt32
  alias Timestamp = UInt32

  NO_GROUP = Group.new(0)
  ALL_CATEGORIES = ~Bitmask.new(0)
  WILDCARD_COLLISION_TYPE = ~CollisionType.new(0)
end
