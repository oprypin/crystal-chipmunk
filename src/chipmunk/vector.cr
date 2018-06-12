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

  # Linearly interpolate (or extrapolate) between *f1* and *f2* by *t* percent.
  def lerp(f1 : Number, f2 : Number, t : Number) : Number
    (f1 * (1.0 - t)) + (f2 * t)
  end

  # Linearly interpolate from *f1* to *f2* by no more than *d*.
  def lerpconst(f1 : Number, f2 : Number, d : Number) : Number
    f1 + (f2 - f1).clamp(-d, d)
  end

  @[Extern]
  # Chipmunk's 2D vector type.
  struct Vect
    property x : Float64, y : Float64

    def initialize(x : Number, y : Number)
      @x = x.to_f
      @y = y.to_f
    end

    # Returns the unit length vector for the given angle (in radians).
    def self.angle(a : Number) : self
      Vect.new(Math.cos(a), Math.sin(a))
    end

    # Check if two vectors are equal.
    #
    # (Be careful when comparing floating point numbers!)
    def ==(v2 : Vect) : Bool
      @x == v2.x && @y == v2.y
    end

    # Add two vectors
    def +(v2 : Vect) : Vect
      Vect.new(@x + v2.x, @y + v2.y)
    end

    # Subtract two vectors.
    def -(v2 : Vect) : Vect
      Vect.new(@x - v2.x, @y - v2.y)
    end

    # Negate a vector.
    def -() : Vect
      Vect.new(-@x, -@y)
    end

    # Scalar multiplication.
    def *(s : Number) : Vect
      Vect.new(@x * s, @y * s)
    end

    # Vector dot product.
    def dot(v2 : Vect) : Float64
      @x * v2.x + @y * v2.y
    end

    # 2D vector cross product analog.
    #
    # The cross product of 2D vectors results in a 3D vector with only a z component.
    # This function returns the magnitude of the z value.
    def cross(v2 : Vect) : Float64
      @x * v2.y - @y * v2.x
    end

    # Returns a perpendicular vector. (90 degree rotation)
    def perp() : Vect
      Vect.new(-@y, @x)
    end

    # Returns a perpendicular vector. (-90 degree rotation)
    def rperp() : Vect
      Vect.new(@y, -@x)
    end

    # Returns the vector projection of the vector onto *v2*.
    def project(v2 : Vect) : Vect
      v2 * (dot v2) / (v2.dot v2)
    end

    # Returns the angular direction the vector is pointing in (in radians).
    def to_angle() : Float64
      Math.atan2(@y, @x)
    end

    # Uses complex number multiplication to rotate the vector by *v2*.
    #
    # Scaling will occur if the vector is not a unit vector.
    def rotate(v2 : Vect) : Vect
      Vect.new(@x * v2.x - @y * v2.y, @x * v2.y + @y * v2.x)
    end

    # Inverse of `rotate`.
    def unrotate(v2 : Vect) : Vect
      Vect.new(@x * v2.x + @y * v2.y, @y * v2.x - @x * v2.y)
    end

    # Returns the squared length of the vector.
    #
    # Faster than `length` when you only need to compare lengths.
    def lengthsq() : Float64
      dot(self)
    end

    # Returns the length of the vector.
    def length() : Float64
      Math.sqrt(dot(self))
    end

    # Linearly interpolate between *v1* and *v2*.
    def self.lerp(v1 : Vect, v2 : Vect, t : Number) : Vect
      (v1 * (1.0 - t)) + (v2 * t)
    end

    # Returns a normalized copy of the vector (unit vector).
    def normalize() : Vect
      # Avoid division by zero
      self * (1.0 / (length + 2.2250738585072014e-308))
    end

    # Spherical linearly interpolate between *v1* and *v2*.
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

    # Spherical linearly interpolate between *v1* towards *v2* by no more than angle *a* radians
    def self.slerpconst(v1 : Vect, v2 : Vect, a : Number) : Vect
      dot = v1.normalize.dot v2.normalize
      omega = Math.acos(dot.clamp(-1.0, 1.0))
      self.slerp(v1, v2, {a, omega}.min / omega)
    end

    # Clamp the vector to length len.
    def clamp(len : Number) : Vect
      dot(self) > len*len ? normalize*len : self
    end

    # Linearly interpolate between *v1* towards *v2* by distance *d*.
    def self.lerpconst(v1 : Vect, v2 : Vect, d : Number) : Vect
      v1 + (v2 - v1).clamp(d)
    end

    # Returns the distance between this vector and *v2*.
    def dist(v2 : Vect) : Float64
      (self - v2).length
    end

    # Returns the squared distance between this vector and *v2*.
    #
    # Faster than `dist` when you only need to compare distances.
    def distsq(v2 : Vect) : Float64
      (self - v2).lengthsq
    end

    # Returns true if the distance between this vector and *v2* is less than *dist*.
    def near?(v2 : Vect, dist : Number) : Bool
      distsq(v2) < dist*dist
    end

    # Returns the closest point on the line segment `a` `b`, to the point stored in this `Vect`.
    def closest_point_on_segment(a : Vect, b : Vect) : Vect
      delta = a - b
      t = (delta.dot(self - b) / delta.lengthsq).clamp(0.0, 1.0)
      b + delta*t
    end
  end

  # Convenience function to create a `Vect`.
  def v(x, y) : Vect
    Vect.new(x, y)
  end

  # Zero `Vect`.
  def vzero() : Vect
    Vect.new(0.0, 0.0)
  end

  @[Extern]
  # Column major 2x3 affine transform.
  struct Transform
    # Identity transform matrix.
    IDENTITY = new

    property a : Float64, b : Float64, c : Float64, d : Float64
    property tx : Float64, ty : Float64

    # Construct a new transform matrix.
    #
    # * (*a*, *b*) is the x basis vector.
    # * (*c*, *d*) is the y basis vector.
    # * (*tx*, *ty*) is the translation.
    def initialize(a : Number = 1, b : Number = 0, c : Number = 0, d : Number = 1, tx : Number = 0, ty : Number = 0)
      @a = a.to_f
      @b = b.to_f
      @c = c.to_f
      @d = d.to_f
      @tx = tx.to_f
      @ty = ty.to_f
    end

    # Construct a new transform matrix in transposed order.
    def self.new_transpose(a : Number, c : Number, tx : Number, b : Number, d : Number, ty : Number) : self
      Transform.new(a, b, c, d, tx, ty)
    end

    # Get the inverse of a transform matrix.
    def inverse() : Transform
      inv_det = 1.0 / (@a*@d - @c*@b)
      Transform.new_transpose(
         @d*inv_det, -@c*inv_det, (@c*@ty - @tx*@d)*inv_det,
        -@b*inv_det,  @a*inv_det, (@tx*@b - @a*@ty)*inv_det
      )
    end

    # Multiply two transformation matrices.
    def *(t2 : Transform) : Transform
      Transform.new_transpose(
        @a*t2.a + @c*t2.bottom, @a*t2.c + @c*t2.d, @a*t2.tx + @c*t2.ty + @tx,
        @b*t2.a + @d*t2.bottom, @b*t2.c + @d*t2.d, @b*t2.tx + @d*t2.ty + @ty
      )
    end

    # Transform an absolute point. (i.e. a vertex)
    def transform_point(p : Vect) : Vect
      Vect.new(@a*p.x + @c*p.y + @tx, @b*p.x + @d*p.y + @ty)
    end

    # Transform a vector (i.e. a normal)
    def transform_vect(v : Vect) : Vect
      Vect.new((@a * v.x) + (@c * v.y), (@b * v.x) + (@d * v.y))
    end

    # Transform a `BB`.
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

    # Create a translation matrix.
    def self.translate(translate : Vect) : self
      Transform.new_transpose(1.0, 0.0, translate.x, 0.0, 1.0, translate.y)
    end

    # Create a scale matrix.
    def self.scale(scale_x : Number, scale_y : Number) : self
      Transform.new_transpose(scale_x, 0.0, 0.0, 0.0, scale_y, 0.0)
    end

    # Create a rotation matrix.
    def self.rotate(radians : Number) : self
      rot = Vect.angle(radians)
      Transform.new_transpose(rot.x, -rot.y, 0.0, rot.y, rot.x, 0.0)
    end

    # Create a rigid transformation matrix. (translation + rotation)
    def self.rigid(translate : Vect, radians : Number) : Transform
      rot = Vect.angle(radians)
      Transform.new_transpose(rot.x, -rot.y, translate.x, rot.y, rot.x, translate.y)
    end

    # Fast inverse of a rigid transformation matrix.
    def self.rigid_inverse() : Transform
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
  # 2x2 matrix type used for tensors and such.
  #
  # (row major: `[[a b][c d]]`)
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
  # Chipmunk's axis-aligned 2D bounding box type. (left, bottom, right, top)
  struct BB
    property left : Float64, bottom : Float64, right : Float64, top : Float64

    def initialize(left : Number = 0, bottom : Number = 0, right : Number = 0, top : Number = 0)
      @left = left.to_f
      @bottom = bottom.to_f
      @right = right.to_f
      @top = top.to_f
    end

    # Constructs a `BB` centered on a point with the given extents (half sizes).
    def self.new_for_extents(c : Vect, hw : Number, hh : Number) : self
      BB.new(c.x - hw, c.y - hh, c.x + hw, c.y + hh)
    end

    # Constructs a `BB` fitting a circle with the position *p* and radius *r*.
    def self.new_for_circle(p : Vect, r : Number) : self
      BB.new_for_extents(p, r, r)
    end

    # Returns true if this `BB` intersects the *other*.
    def intersects?(other : BB) : Bool
      @left <= other.right && other.left <= @right && @bottom <= other.top && other.bottom <= @top
    end

    # Returns true if the *other* `BB` lies completely within this one.
    def contains?(other : BB) : Bool
      @left <= other.left && @right >= other.right && @bottom <= other.bottom && @top >= other.top
    end

    # Returns true if this `BB` contains the *point*.
    def contains?(point : Vect) : Bool
      @left <= point.x && @right >= point.x && @bottom <= point.y && @top >= point.y
    end

    # Returns a bounding box that holds both bounding boxes.
    def merge(other : BB) : BB
      BB.new({@left, other.left}.min, {@bottom, other.bottom}.min, {@right, other.right}.max, {@top, other.top}.max)
    end

    # Returns the minimal bounding box that contains both this `BB` and the *point*.
    def expand(point : Vect) : BB
      BB.new({@left, point.x}.min, {@bottom, point.y}.min, {@right, point.x}.max, {@top, point.y}.max)
    end

    # Returns the center of a bounding box.
    def center() : Vect
      Vect.lerp(Vect.new(@left, @bottom), Vect.new(@right, @top), 0.5)
    end

    # Returns the area of the bounding box.
    def area() : Float64
      (@right - @left) * (@top - @bottom)
    end

    # Returns the fraction along the segment query the `BB` is hit.
    #
    # Returns INFINITY if it doesn't hit.
    def segment_query(a : Vect, b : Vect) : Float64
      idx = 1.0 / (b.x - a.x)
      tx1 = @left == a.x ? -Float64::INFINITY : (@left - a.x) * idx
      tx2 = @right == a.x ? Float64::INFINITY : (@right - a.x) * idx
      txmin = {tx1, tx2}.min
      txmax = {tx1, tx2}.max
      idy = 1.0 / (b.y - a.y)
      ty1 = @bottom == a.y ? -Float64::INFINITY : (@bottom - a.y) * idy
      ty2 = @top == a.y ? Float64::INFINITY : (@top - a.y) * idy
      tymin = {ty1, ty2}.min
      tymax = {ty1, ty2}.max
      if tymin <= txmax && txmin <= tymax
        min = {txmin, tymin}.max
        max = {txmax, tymax}.min
        if 0.0 <= max && min <= 1.0
          return {min, 0.0}.max
        end
      end
      Float64::INFINITY
    end

    # Return true if the bounding box intersects the line segment with ends *a* and *b*.
    def intersects_segment?(a : Vect, b : Vect) : Bool
      segment_query(a, b) != Float64::INFINITY
    end

    # Clamp a vector to a bounding box
    def clamp_vect(v : Vect) : Vect
      Vect.new(v.x.clamp(@left, @right), v.y.clamp(@bottom, @top))
    end

    # Wrap a vector to a bounding box.
    def wrap_vect(v : Vect) : Vect
      dx = (@right - @left).abs
      modx = (v.x - @left).fdiv(dx)
      x = modx > 0.0 ? modx : modx + dx
      dy = (@top - @bottom).abs
      mody = (v.y - @bottom).fdiv(dy)
      y = mody > 0.0 ? mody : mody + dy
      Vect.new(x + @left, y + @bottom)
    end

    # Returns a bounding box offseted by *v*.
    def offset(v : Vect) : BB
      BB.new(@left + v.x, @bottom + v.y, @right + v.x, @top + v.y)
    end
  end
end
