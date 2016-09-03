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
    def self.from(this : LibCP::Space*) : self
      LibCP.space_get_user_data(this).as(self)
    end
    # :nodoc:
    def self.from?(this : LibCP::Space*) : self?
      self.from(this) if this
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

    #def add_post_step_callback

    def point_query(point : Point, max_distance : Number, filter : ShapeFilter, &block : PointQueryInfo ->)
      # Can't use the proper interface because https://github.com/crystal-lang/crystal/issues/605
      context = PointQueryContext.new(point: point, max_distance: max_distance, filter: filter, func: nil)
      bb = BB.new_for_circle(point, {max_distance, 0.0}.max)

      LibCP.space_lock(self)
      {% for index in %w[dynamic_shapes static_shapes] %}
        index = to_unsafe.value.{{index.id}}
        index.value.klass.value.query.call(index, pointerof(context), bb, ->(context, shape, id, data) {
          a = shape.value.filter
          b = context.value.filter

          unless (
            a.group != 0 && a.group == b.group ||
            (a.categories & b.mask) == 0 || (b.categories & a.mask) == 0
          )
            LibCP.shape_point_query(shape, context.value.point, out info)

            if info.shape && info.distance < context.value.max_distance
              info.shape = shape
              data.as(typeof(block)*).value.call(info)
            end
          end
          id
        }, pointerof(block))
      {% end %}
      LibCP.space_unlock(self, true)
    end

    def point_query_nearest(point : Vect, max_distance : Number, filter : ShapeFilter) : PointQueryInfo
      shape = LibCP.space_point_query_nearest(self, point, max_distance, filter, out info)
      #info.shape = shape
      info
    end

    #def segment_query

    def segment_query_first(start : Vect, end : Vect, radius : Float64, filter : ShapeFilter) : SegmentQueryInfo
      LibCP.space_segment_query_first(self, start, end, radius, filter, out info)
      info
    end

    #def bb_query

    #def shape_query

    def each_body(&block : Body ->)
      LibCP.space_each_body(self, ->(body, data) {
        data.as(typeof(block)*).value.call(Body.from(body))
      }, pointerof(block))
    end

    def each_shape(&block : Shape ->)
      LibCP.space_each_shape(self, ->(shape, data) {
        data.as(typeof(block)*).value.call(Shape.from(shape))
      }, pointerof(block))
    end

    def each_constraint(&block : Constraint ->)
      LibCP.space_each_constraint(self, ->(constraint, data) {
        data.as(typeof(block)*).value.call(Constraint.from(constraint))
      }, pointerof(block))
    end

    def reindex_static()
      LibCP.space_reindex_static(self)
    end

    def reindex(shape : Shape)
      LibCP.space_reindex_shape(self, shape)
    end

    def reindex_shapes_for(body : Body)
      LibCP.space_reindex_shapes_for_body(self, body)
    end

    def use_spatial_hash(dim : Number, count : Int)
      LibCP.space_use_spatial_hash(self, dim, count)
    end

    def step(dt : Number)
      LibCP.space_step(self, dt)
    end
  end
end
