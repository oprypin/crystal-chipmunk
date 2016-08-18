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
      vmult(v2, dot(v2) / v2.dot(v2))
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
      self * (1.0 / (length + Float64::MIN))
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

  @[Extern]
  struct Transform
    property a : Float64, b : Float64, c : Float64, d : Float64
    property tx : Float64, ty : Float64

    def initialize(a : Number, b : Number, c : Number, d : Number, tx : Number, ty : Number)
      @a = a.to_f
      @b = b.to_f
      @c = c.to_f
      @d = d.to_f
      @tx = tx.to_f
      @ty = ty.to_f
    end
    def initialize()
      @a = 1.0
      @b = 0.0
      @c = 0.0
      @d = 1.0
      @tx = 0.0
      @ty = 0.0
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
        @a*t2.a + @c*t2.b, @a*t2.c + @c*t2.d, @a*t2.tx + @c*t2.ty + @tx,
        @b*t2.a + @d*t2.b, @b*t2.c + @d*t2.d, @b*t2.tx + @d*t2.ty + @ty
      )
    end

    def transform(p : Vect) : Vect
      Vect.new(@a*p.x + @c*p.y + @tx, @b*p.x + @d*p.y + @ty)
    end

    def transform(v : Vect) : Vect
      Vect.new((@a * v.x) + (@c * v.y), (@b * v.x) + (@d * v.y))
    end

    def transform(bb : BB) : BB
      center = bb.center
      hw = (bb.r - bb.l) * 0.5
      hh = (bb.t - bb.b) * 0.5
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
        2.0/(bb.r - bb.l), 0.0, -(bb.r + bb.l)/(bb.r - bb.l),
        0.0, 2.0/(bb.t - bb.b), -(bb.t + bb.b)/(bb.t - bb.b)
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
    property l : Float64, b : Float64, r : Float64, t : Float64

    def initialize(l : Number, b : Number, r : Number, t : Number)
      @l = l.to_f
      @b = b.to_f
      @r = r.to_f
      @t = t.to_f
    end

    def self.new_for_extents(c : Vect, hw : Number, hh : Number) : self
      BB.new(c.x - hw, c.y - hh, c.x + hw, c.y + hh)
    end

    def self.new_for_circle(p : Vect, r : Number) : self
      BB.new_for_extents(p, r, r)
    end

    def intersects?(other : BB) : Bool
      @l <= other.r && other.l <= @r && @b <= other.t && other.b <= @t
    end

    def contains?(other : BB) : Bool
      @l <= other.l && @r >= other.r && @b <= other.b && @t >= other.t
    end

    def contains?(v : Vect) : Bool
      @l <= v.x && @r >= v.x && @b <= v.y && @t >= v.y
    end

    def merge(b : BB) : BB
      BB.new({@l, b.l}.min, {@b, b.b}.min, {@r, b.r}.max, {@t, b.t}.max)
    end

    def expand(v : Vect) : BB
      BB.new({@l, v.x}.min, {@b, v.y}.min, {@r, v.x}.max, {@t, v.y}.max)
    end

    def center() : Vect
      vlerp(Vect.new(@l, @b), Vect.new(@r, @t), 0.5)
    end

    def area() : Float64
      (@r - @l) * (@t - @b)
    end

    def merged_area(b : BB) : Float64
      ({@r, b.r}.max - {@l, b.l}.min) * ({@t, b.t}.max - {@b, b.b}.min)
    end

    def segment_query(a : Vect, b : Vect) : Float64
      idx = 1.0 / (b.x - a.x)
      tx1 = @l == a.x ? Float64::MIN : (@l - a.x) * idx
      tx2 = @r == a.x ? Float64::MAX : (@r - a.x) * idx
      txmin = {tx1, tx2}.min
      txmax = {tx1, tx2}.max
      idy = 1.0 / (b.y - a.y)
      ty1 = @b == a.y ? Float64::MIN : (@b - a.y) * idy
      ty2 = @t == a.y ? Float64::MAX : (@t - a.y) * idy
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
      Vect.new(v.x.clamp(@l, @r), v.y.clamp(@b, @t))
    end

    def wrap_vect(v : Vect) : Vect
      dx = (@r - @l).abs
      modx = (v.x - @l).fdiv(dx)
      x = modx > 0.0 ? modx : modx + dx
      dy = (@t - @b).abs
      mody = (v.y - @b).fdiv(dy)
      y = mody > 0.0 ? mody : mody + dy
      Vect.new(x + @l, y + @b)
    end

    def offset(v : Vect) : BB
      BB.new(@l + v.x, @b + v.y, @r + v.x, @t + v.y)
    end
  end

  @[Extern]
  struct PointQueryInfo
    @shape : LibCP::Shape*
    property point : Vect
    property distance : Float64
    property gradient : Vect

    def initialize(shape : Shape, @point : Vect, @distance : Float64, @gradient : Vect)
      @shape = shape ? shape.to_unsafe : Pointer(Shape).null
    end

    def shape : Shape?
      Shape.from(@shape)
    end
    def shape=(shape : Shape?)
      @shape = shape ? shape.to_unsafe : Pointer(Shape).null
    end
  end

  @[Extern]
  struct SegmentQueryInfo
    @shape : LibCP::Shape*
    property point : Vect
    property normal : Vect
    property alpha : Float64

    def initialize(shape : Shape?, @point : Vect, @normal : Vect, @alpha : Float64)
      @shape = shape ? shape.to_unsafe : Pointer(Shape).null
    end

    def shape : Shape?
      Shape.from(@shape)
    end
    def shape=(shape : Shape?)
      @shape = shape ? shape.to_unsafe : Pointer(Shape).null
    end
  end

  @[Extern]
  struct ContactPointSetItem
    property point_a : Vect, point_b : Vect
    property distance : Float64

    def initialize(@point_a : Vect, @point_b : Vect, @distance : Float64)
    end
  end

  @[Extern]
  struct ContactPointSet
    property count : Int32
    property normal : Vect
    @points : ContactPointSetItem[2]

    def initialize(points : Slice(ContactPointSetItem), @normal : Vect)
      @count = points.size
      @points = uninitialized ContactPointSetItem[2]
      points.copy_to(@points, @count)
    end

    def points : Slice(ContactPointSetItem)
      @points.to_unsafe.to_slice(@count)
    end
  end

  @[Extern]
  struct ShapeFilter
    property group : LibCP::Group
    property categories : LibCP::Bitmask
    property mask : LibCP::Bitmask

    def initialize(@group : LibCP::Group, @categories : LibCP::Bitmask, @mask : LibCP::Bitmask)
    end
  end
end

require "./lib"

module CP
  extend self

  def moment_for_circle(m : Number, r1 : Number, r2 : Number, offset : Vect) : Float64
    LibCP.moment_for_circle(m, r1, r2, offset)
  end

  def area_for_circle(r1 : Number, r2 : Number) : Float64
    LibCP.area_for_circle(r1, r2)
  end

  def moment_for_segment(m : Number, a : Vect, b : Vect, radius : Number) : Float64
    LibCP.moment_for_segment(m, a, b, radius)
  end

  def area_for_segment(a : Vect, b : Vect, radius : Number) : Float64
    LibCP.area_for_segment(a, b, radius)
  end

  def moment_for_poly(m : Number, verts : Array(Vect)|Slice(Vect), offset : Vect, radius : Number) : Float64
    LibCP.moment_for_poly(m, verts.size, verts, offset, radius)
  end

  def area_for_poly(verts : Array(Vect)|Slice(Vect), radius : Number) : Float64
    LibCP.area_for_poly(verts.size, verts, radius)
  end

  def centroid_for_poly(verts : Array(Vect)|Slice(Vect)) : Vect
    LibCP.centroid_for_poly(verts.size, verts)
  end

  def moment_for_box(m : Number, width : Number, height : Number) : Float64
    LibCP.moment_for_box(m, width, height)
  end

  def moment_for_box(m : Number, box : BB) : Float64
    LibCP.moment_for_box2(m, box)
  end

  def convex_hull(verts : Array(Vect)|Slice(Vect), tol : Number) : {Slice(Vect), Int32}
    result = Slice(Vect).new(verts.size)
    LibCP.convex_hull(verts.size, verts, result, out first, tol)
    {result, first}
  end

  def lerp(f1 : Number, f2 : Number, t : Number) : Number
    (f1 * (1.0 - t)) + (f2 * t)
  end

  def lerpconst(f1 : Number, f2 : Number, d : Number) : Number
    f1 + (f2 - f1).clamp(-d, d)
  end

  def spatial_index_destroy(index : SpatialIndex*)
    if (klass = index.value.klass)
      klass.value.destroy.call(index)
    end
  end

  def spatial_index_count(index : SpatialIndex*) : Int32
    index.value.klass.value.count.call(index)
  end

  def spatial_index_each(index : SpatialIndex*, func : SpatialIndexIteratorFunc, data : Void*)
    index.value.klass.value.each.call(index, func, data)
  end

  def spatial_index_contains(index : SpatialIndex*, obj : Void*, hashid : HashValue) : Bool
    index.value.klass.value.contains.call(index, obj, hashid)
  end

  def spatial_index_insert(index : SpatialIndex*, obj : Void*, hashid : HashValue)
    index.value.klass.value.insert.call(index, obj, hashid)
  end

  def spatial_index_remove(index : SpatialIndex*, obj : Void*, hashid : HashValue)
    index.value.klass.value.remove.call(index, obj, hashid)
  end

  def spatial_index_reindex(index : SpatialIndex*)
    index.value.klass.value.reindex.call(index)
  end

  def spatial_index_reindex_object(index : SpatialIndex*, obj : Void*, hashid : HashValue)
    index.value.klass.value.reindex_object.call(index, obj, hashid)
  end

  def spatial_index_query(index : SpatialIndex*, obj : Void*, bb : BB, func : SpatialIndexQueryFunc, data : Void*)
    index.value.klass.value.query.call(index, obj, bb, func, data)
  end

  def spatial_index_segment_query(index : SpatialIndex*, obj : Void*, a : Vect, b : Vect, t_exit : Float64, func : SpatialIndexSegmentQueryFunc, data : Void*)
    index.value.klass.value.segment_query.call(index, obj, a, b, t_exit, func, data)
  end

  def spatial_index_reindex_query(index : SpatialIndex*, func : SpatialIndexQueryFunc, data : Void*)
    index.value.klass.value.reindex_query.call(index, func, data)
  end


  abstract class Shape
    abstract def to_unsafe : LibCP::Shape

    # :nodoc:
    def self.from(this : LibCP::Shape*) : self?
      return nil if !this
      LibCP.shape_get_user_data(this).as(self)
    end

    def finalize
      LibCP.shape_destroy(self)
    end

    def cache_bb : BB
      LibCP.shape_cache_bb(self)
    end

    def update(transform : Transform) : BB
      LibCP.shape_update(self, transform)
    end

    def point_query(p : Vect) : PointQueryInfo
      LibCP.shape_point_query(self, p, out info)
      info
    end

    def segment_query(a : Vect, b : Vect, radius : Number) : SegmentQueryInfo
      LibCP.shape_segment_query(self, a, b, radius, out info)
      info
    end

    def collide(b : Shape) : ContactPointSet
      LibCP.shapes_collide(self, b)
    end

    def space : Space?
      Space.from(LibCP.shape_get_space(self))
    end

    def body : Body?
      Body.from(LibCP.shape_get_space(self))
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
      LibCP.shape_set_density(self, sensor)
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

    def collision_type : LibCP::CollisionType
      LibCP.shape_get_collision_type(self)
    end
    def collision_type=(collision_type : LibCP::CollisionType)
      LibCP.shape_set_collision_type(self, collision_type)
    end

    def filter : ShapeFilter
      LibCP.shape_get_filter(self)
    end
    def filter=(filter : ShapeFilter)
      LibCP.shape_set_filter(self, filter)
    end
  end

  class CircleShape < Shape
    def initialize(body : Body, radius : Number, offset : Vect)
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

  class SegmentShape < Shape
    def initialize(body : Body, a : Vect, b : Vect, radius : Number)
      @shape = uninitialized LibCP::SegmentShape
      LibCP.segment_shape_init(pointerof(@shape), body, a, b, radius)
      LibCP.shape_set_user_data(self, self.as(Void*))
    end

    # :nodoc:
    def to_unsafe : LibCP::Shape*
      pointerof(@shape).as(LibCP::Shape*)
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

  class PolyShape < Shape
    include Enumerable(Vect)
    include Indexable(Vect)

    def initialize(body : Body, verts : Array(Vert)|Slice(Vert), transform : Transform, radius : Number)
      @shape = uninitialized LibCP::PolyShape
      LibCP.poly_shape_init(pointerof(@shape), body, verts.size, verts, transform, radius)
      LibCP.shape_set_user_data(self, self.as(Void*))
    end
    def initialize(body : Body, verts : Array(Vert)|Slice(Vert), radius : Number)
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

    def [](index : Int32) : Vect
      LibCP.poly_shape_get_vect(self, index)
    end

    def radius : Float64
      LibCP.poly_shape_get_radius(self)
    end
  end

  class BoxShape < PolyShape
    def initialize(body : Body, width : Number, height : Number, radius : Number)
      @shape = uninitialized LibCP::PolyShape
      LibCP.box_shape_init(pointerof(@shape), body, width, height, radius)
      LibCP.shape_set_user_data(self, self.as(Void*))
    end
    def initialize(body : Body, box : BB, radius : Number)
      @shape = uninitialized LibCP::PolyShape
      LibCP.box_shape_init(pointerof(@shape), body, box, radius)
      LibCP.shape_set_user_data(self, self.as(Void*))
    end
  end

  class Body
    enum Type
      DYNAMIC
      KINEMATIC
      STATIC
    end

    def initialize(mass : Number, moment : Number)
      @body = uninitialized LibCP::Body
      LibCP.body_init(self, mass, moment)
      LibCP.body_set_user_data(self, self.as(Void*))
    end

    def self.new_kinematic() : self
      body = self.new(0, 0)
      body.type = Type::KINEMATIC
      body
    end
    def self.new_static() : self
      body = self.new(0, 0)
      body.type = Type::STATIC
      body
    end

    # :nodoc:
    def to_unsafe : LibCP::Body*
      pointerof(@body)
    end
    # :nodoc:
    def self.from(this : LibCP::Body*) : self?
      return nil if !this
      LibCP.body_get_user_data(this).as(self)
    end

    def finalize
      LibCP.body_destroy(self)
    end

    def activate()
      LibCP.body_activate(self)
    end

    def activate_static(filter : Shape?)
      LibCP.body_activate_static(self, filter)
    end

    def sleep()
      LibCP.body_sleep(self)
    end
    def sleep_with_group(group : Body?)
      LibCP.body_sleep_with_group(self, group)
    end

    def sleeping? : Bool
      LibCP.body_is_sleeping(self)
    end

    def type : Type
      LibCP.body_get_type(self)
    end
    def type=(type : Type)
      LibCP.body_set_type(self, type)
    end

    def space : Space?
      Space.new(LibCP.body_get_space(self))
    end

    def mass : Float64
      LibCP.body_get_mass(self)
    end
    def mass=(mass : Number)
      LibCP.body_set_mass(self, mass)
    end

    def moment : Float64
      LibCP.body_get_moment(self)
    end
    def moment=(moment : Number)
      LibCP.body_set_moment(self, moment)
    end

    def position : Vect
      LibCP.body_get_position(self)
    end
    def position=(position : Vect)
      LibCP.body_set_position(self, position)
    end

    def center_of_gravity : Vect
      LibCP.body_get_center_of_gravity(self)
    end
    def center_of_gravity=(center_of_gravity : Vect)
      LibCP.body_set_center_of_gravity(self, center_of_gravity)
    end

    def velocity : Vect
      LibCP.body_get_velocity(self)
    end
    def velocity=(velocity : Vect)
      LibCP.body_set_velocity(self, velocity)
    end

    def force : Vect
      LibCP.body_get_force(self)
    end
    def force=(force : Vect)
      LibCP.body_set_force(self, force)
    end

    def angle : Float64
      LibCP.body_get_angle(self)
    end
    def angle=(angle : Number)
      LibCP.body_set_angle(self, angle)
    end

    def angular_velocity : Float64
      LibCP.body_get_angular_velocity(self)
    end
    def angular_velocity=(angular_velocity : Number)
      LibCP.body_set_angular_velocity(self, angular_velocity)
    end

    def torque : Float64
      LibCP.body_get_torque(self)
    end
    def torque=(torque : Number)
      LibCP.body_set_torquee(self, torque)
    end

    def rotation : Float64
      LibCP.body_get_rotation(self)
    end

    def local_to_world(point : Vect) : Vect
      LibCP.body_local_to_world(self, point)
    end
    def world_to_local(point : Vect) : Vect
      LibCP.body_world_to_local(self, point)
    end

    def apply_force_at_world_point(force : Vect, point : Vect)
      LibCP.body_apply_force_at_world_point(self, force, point)
    end
    def apply_force_at_local_point(force : Vect, point : Vect)
      LibCP.body_apply_force_at_local_point(self, force, point)
    end

    def apply_impulse_at_world_point(impulse : Vect, point : Vect)
      LibCP.body_apply_impulse_at_world_point(self, impulse, point)
    end
    def apply_impulse_at_local_point(impulse : Vect, point : Vect)
      LibCP.body_apply_impulse_at_local_point(self, impulse, point)
    end

    def get_velocity_at_world_point(point : Vect) : Vect
      LibCP.body_get_velocity_at_world_point(self, point)
    end
    def get_velocity_at_local_point(point : Vect) : Vect
      LibCP.body_get_velocity_at_local_point(self, point)
    end

    def kinetic_energy : Float64
      LibCP.body_kinetic_energy(self)
    end

    def each_shape(&block : Shape ->)
      LibCP.body_each_shape(self, ->(body, shape, data) {
        data.as(typeof(block)*).value.call(Shape.from(shape).not_nil!)
      }, pointerof(block))
    end
    def each_constraint(&block : Constraint ->)
      LibCP.body_each_constraint(self, ->(body, constraint, data) {
        data.as(typeof(block)*).value.call(Shape.from(constraint).not_nil!)
      }, pointerof(block))
    end
    def each_arbiter(&block : Arbiter ->)
      LibCP.body_each_arbiter(self, ->(body, arbiter, data) {
        data.as(typeof(block)*).value.call(Arbiter.from(arbiter).not_nil!)
      }, pointerof(block))
    end
  end

  class Space
    def initialize()
      @space = uninitialized LibCP::Space
      LibCP.space_init(self)
      LibCP.space_set_user_data(self, self.as(Void*))
    end

    # :nodoc:
    def to_unsafe : LibCP::Space*
      pointerof(@space)
    end
    # :nodoc:
    def self.from(this : LibCP::Space*) : self?
      return nil if !this
      LibCP.space_get_user_data(this).as(self)
    end

    def finalize
      LibCP.space_destroy(self)
    end

    def iterations : Int32
      LibCP.space_get_iterations(self)
    end
    def iterations=(iterations : Int)
      LibCP.space_set_iterations(self, iterations)
    end

    def gravity : Vect
      LibCP.space_get_gravity(self)
    end
    def gravity=(gravity : Vect)
      LibCP.space_set_gravity(self, gravity)
    end

    def damping : Float64
      LibCP.space_get_damping(self)
    end
    def damping=(damping : Number)
      LibCP.space_set_damping(self, damping)
    end

    def idle_speed_threshold : Float64
      LibCP.space_get_idle_speed_threshold(self)
    end
    def idle_speed_threshold=(idle_speed_threshold : Number)
      LibCP.space_set_idle_speed_threshold(self, idle_speed_threshold)
    end

    def sleep_time_threshold : Float64
      LibCP.space_get_sleep_time_threshold(self)
    end
    def sleep_time_threshold=(sleep_time_threshold : Number)
      LibCP.space_set_sleep_time_threshold(self, sleep_time_threshold)
    end

    def collision_slop : Float64
      LibCP.space_get_collision_slop(self)
    end
    def collision_slop=(collision_slop : Number)
      LibCP.space_set_collision_slop(self, collision_slop)
    end

    def collision_bias : Float64
      LibCP.space_get_collision_bias(self)
    end
    def collision_bias=(collision_bias : Number)
      LibCP.space_set_collision_bias(self, collision_bias)
    end

    def collision_persistence : Timestamp
      LibCP.space_get_collision_persistence(self)
    end
    def collision_persistence=(collision_persistence : Timestamp)
      LibCP.space_set_collision_persistence(self, collision_persistence)
    end

    @static_body = Body.new_static
    def static_body : Body
      @static_body
    end

    def current_time_step : Float64
      LibCP.space_get_current_time_step(self)
    end

    def locked? : Bool
      LibCP.space_is_locked(self)
    end

    #def add_default_collision_handler() : CollisionHandler
    #end

    #def add_collision_handler(a : CollisionType, b : CollisionType) : CollisionHandler
    #end

    #def add_wildcard_handler(type : CollisionType) : CollisionHandler
    #end

    def add(shape : Shape)
      LibCP.space_add_shape(self, shape)
      shape
    end
    def add(body : Body)
      LibCP.space_add_body(self, body)
      body
    end
    def add(constraint : Constraint)
      LibCP.space_add_constraint(self, constraint)
      constraint
    end

    def remove(shape : Shape)
      LibCP.space_remove_shape(self, shape)
    end
    def remove(body : Body)
      LibCP.space_remove_body(self, body)
    end
    def remove(constraint : Constraint)
      LibCP.space_remove_constraint(self, constraint)
    end

    def contains?(shape : Shape) : Bool
      LibCP.space_contains_shape(self, shape)
    end
    def contains?(body : Body) : Bool
      LibCP.space_contains_body(self, body)
    end
    def contains?(constraint : Constraint) : Bool
      LibCP.space_contains_constraint(self, constraint)
    end

    def step(dt : Number)
      LibCP.space_step(self, dt)
    end
  end
end
