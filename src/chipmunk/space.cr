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
      @in_step = false
      @todo = {} of (Body | Shape | Constraint) => Bool
      LibCP.space_init(self)
      LibCP.space_set_user_data(self, self.as(Void*))
    end

    # :nodoc:
    def to_unsafe : LibCP::Space*
      pointerof(@space)
    end
    # :nodoc:
    def self.[](this : LibCP::Space*) : self
      LibCP.space_get_user_data(this).as(self)
    end
    # :nodoc:
    def self.[]?(this : LibCP::Space*) : self?
      self[this] if this
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

    def add_collision_handler(a : Int, b : Int, handler : CollisionHandler) : CollisionHandler
      handler.prime!(LibCP.space_add_collision_handler(self, a, b))
    end

    def add_collision_handler(type : Int, handler : CollisionHandler) : CollisionHandler
      handler.prime!(LibCP.space_add_wildcard_handler(self, type))
    end

    def add_collision_handler(handler : CollisionHandler) : CollisionHandler
      handler.prime!(LibCP.space_add_default_collision_handler(self))
    end

    private def _add(shape : Shape)
      LibCP.space_add_shape(self, shape)
      shape
    end
    private def _add(body : Body)
      LibCP.space_add_body(self, body)
      body
    end
    private def _add(constraint : Constraint)
      LibCP.space_add_constraint(self, constraint)
      constraint
    end

    def add(*items : (Shape | Body | Constraint))
      items.each do |item|
        if @in_step
          @todo[item] = true
        else
          _add item
        end
      end
      items[0]
    end

    private def _remove(shape : Shape)
      LibCP.space_remove_shape(self, shape)
    end
    private def _remove(body : Body)
      LibCP.space_remove_body(self, body)
    end
    private def _remove(constraint : Constraint)
      LibCP.space_remove_constraint(self, constraint)
    end

    def remove(*items : (Shape | Body | Constraint))
      items.each do |item|
        if @in_step
          @todo[item] = false
        else
          _remove item
        end
      end
      items[0]
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

    _cp_gather point_query : PointQueryInfo,
    def point_query(point : Vect, max_distance : Number = 0, filter : ShapeFilter = ShapeFilter::ALL, &block : PointQueryInfo ->)
      LibCP.space_point_query(self, point, max_distance, filter, ->(shape, point, distance, gradient, data) {
        data.as(typeof(block)*).value.call(PointQueryInfo.new(Shape[shape], point, distance, gradient))
      }, pointerof(block))
    end

    def point_query_nearest(point : Vect, max_distance : Number = 0, filter : ShapeFilter = ShapeFilter::ALL) : PointQueryInfo?
      if (shape = LibCP.space_point_query_nearest(self, point, max_distance, filter, out info))
        info.shape = shape
        info
      end
    end

    _cp_gather segment_query : SegmentQueryInfo,
    def segment_query(start : Vect, end end_ : Vect, radius : Number = 0, filter : ShapeFilter = ShapeFilter::ALL, &block : SegmentQueryInfo ->)
      LibCP.space_segment_query(self, start, end_, radius, filter, ->(shape, point, normal, alpha, data) {
        data.as(typeof(block)*).value.call(SegmentQueryInfo.new(Shape[shape], point, normal, alpha))
      }, pointerof(block))
    end

    def segment_query_first(start : Vect, end end_ : Vect, radius : Number = 0, filter : ShapeFilter = ShapeFilter::ALL) : SegmentQueryInfo?
      if LibCP.space_segment_query_first(self, start, end_, radius, filter, out info)
        info
      end
    end

    _cp_gather bb_query : Shape,
    def bb_query(bb : BB, filter : ShapeFilter = ShapeFilter::ALL, &block : Shape ->)
      LibCP.space_bb_query(self, bb, filter, ->(shape, data) {
        data.as(typeof(block)*).value.call(Shape[shape])
      }, pointerof(block))
    end

    _cp_gather shape_query : Shape,
    def shape_query(shape : Shape, &block : (Shape, ContactPointSet) ->)
      LibCP.space_shape_query(self, shape, ->(shape, contact_point_set, data) {
        data.as(typeof(block)*).value.call(Shape[shape], contact_point_set.value)
      }, pointerof(block))
    end

    {% for type in %w[Body Shape Constraint] %}
      {% name = type.downcase.id %}
      {% type = type.id %}

      _cp_gather {% if type == "Body" %}bodies{% else %}{{name + "s"}}{% end %} : {{type}},
      def each_{{name}}(&block : {{type}} ->)
        LibCP.space_each_{{name}}(self, ->(item, data) {
          data.as(typeof(block)*).value.call({{type}}[item])
        }, pointerof(block))
      end
    {% end %}

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
      @in_step = true
      LibCP.space_step(self, dt)
      @in_step = false

      @todo.each do |item, add|
        if add
          _add item
        else
          _remove item
        end
      end
      @todo.clear
    end
  end
end
