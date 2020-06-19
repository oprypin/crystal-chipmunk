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
  # Spaces are the basic unit of simulation. You add rigid bodies, shapes
  # and joints to it and then step them all forward together through time.
  class Space
    alias Timestamp = UInt32

    @space : LibCP::Space*

    def initialize(*, threaded : Bool = true)
      @threaded = threaded
      @bodies = Set(Body).new
      @constraints = Set(Constraint).new
      @shapes = Set(Shape).new
      @in_step = false
      @todo = {} of (Body | Shape | Constraint) => Bool
      @collision_handlers = Set(CollisionHandler).new
      @space = threaded? LibCP.hasty_space_new, LibCP.space_new
      LibCP.space_set_user_data(self, self.as(Void*))
    end

    private macro threaded?(yes, no)
      {% if flag?(:win32) %}
        {{no}}
      {% else %}
        @threaded ? {{yes}} : {{no}}
      {% end %}
    end

    # :nodoc:
    def to_unsafe : LibCP::Space*
      @space
    end
    # :nodoc:
    def self.[](this : LibCP::Space*) : self
      LibCP.space_get_user_data(this).as(self)
    end
    # :nodoc:
    def self.[]?(this : LibCP::Space*) : self?
      self[this] if this
    end

#     def finalize
#       LibCP.space_destroy(self)
#     end

    # Number of iterations to use in the impulse solver to solve contacts and other constraints.
    #
    # Chipmunk uses an iterative solver to figure out the forces between
    # objects in the space. What this means is that it builds a big list of
    # all of the collisions, joints, and other constraints between the
    # bodies and makes several passes over the list considering each one
    # individually. The number of passes it makes is the iteration count,
    # and each iteration makes the solution more accurate. If you use too
    # many iterations, the physics should look nice and solid, but may use
    # up too much CPU time. If you use too few iterations, the simulation
    # may seem mushy or bouncy when the objects should be solid. Setting
    # the number of iterations lets you balance between CPU usage and the
    # accuracy of the physics. Chipmunk's default of 10 iterations is
    # sufficient for most simple games.
    def iterations : Int32
      LibCP.space_get_iterations(self)
    end
    def iterations=(iterations : Int)
      LibCP.space_set_iterations(self, iterations)
    end

    # Gravity to pass to rigid bodies when integrating velocity.
    #
    # Defaults to (0,0).
    def gravity : Vect
      LibCP.space_get_gravity(self)
    end
    def gravity=(gravity : Vect)
      LibCP.space_set_gravity(self, gravity)
    end

    # Damping rate expressed as the fraction of velocity bodies retain each second.
    #
    # A value of 0.9 would mean that each body's velocity will drop 10% per second.
    # The default value is 1.0, meaning no damping is applied.
    #
    # *Note:* This damping value is different than those of `DampedSpring` and `DampedRotarySpring`.
    def damping : Float64
      LibCP.space_get_damping(self)
    end
    def damping=(damping : Number)
      LibCP.space_set_damping(self, damping)
    end

    # Speed threshold for a body to be considered idle.
    #
    # The default value of 0 means to let the space guess a good threshold based on gravity.
    def idle_speed_threshold : Float64
      LibCP.space_get_idle_speed_threshold(self)
    end
    def idle_speed_threshold=(idle_speed_threshold : Number)
      LibCP.space_set_idle_speed_threshold(self, idle_speed_threshold)
    end

    # Time a group of bodies must remain idle in order to fall asleep.
    #
    # Enabling sleeping also implicitly enables the the contact graph.
    # The default value of INFINITY disables the sleeping algorithm.
    def sleep_time_threshold : Float64
      LibCP.space_get_sleep_time_threshold(self)
    end
    def sleep_time_threshold=(sleep_time_threshold : Number)
      LibCP.space_set_sleep_time_threshold(self, sleep_time_threshold)
    end

    # Amount of encouraged penetration between colliding shapes.
    #
    # Used to reduce oscillating contacts and keep the collision cache warm.
    # Defaults to 0.1. If you have poor simulation quality,
    # increase this number as much as possible without allowing visible amounts of overlap.
    def collision_slop : Float64
      LibCP.space_get_collision_slop(self)
    end
    def collision_slop=(collision_slop : Number)
      LibCP.space_set_collision_slop(self, collision_slop)
    end

    # Determines how fast overlapping shapes are pushed apart.
    #
    # Expressed as a fraction of the error remaining after each second.
    # Defaults to `(1.0 - 0.1)**60.0` meaning that Chipmunk fixes 10% of overlap each frame at 60Hz.
    def collision_bias : Float64
      LibCP.space_get_collision_bias(self)
    end
    def collision_bias=(collision_bias : Number)
      LibCP.space_set_collision_bias(self, collision_bias)
    end

    # Number of frames that contact information should persist.
    #
    # Defaults to 3. There is probably never a reason to change this value.
    def collision_persistence : Timestamp
      LibCP.space_get_collision_persistence(self)
    end
    def collision_persistence=(collision_persistence : Timestamp)
      LibCP.space_set_collision_persistence(self, collision_persistence)
    end

    @static_body : Body?
    # The `Space` provided static body for a given `Space`.
    #
    # This is merely provided for convenience and you are not required to use it.
    def static_body : Body
      @static_body ||= add Body.new_static
    end

    # Returns the current (or most recent) time step used with the given space.
    #
    # Useful from callbacks if your time step is not a compile-time global.
    def current_time_step : Float64
      LibCP.space_get_current_time_step(self)
    end

    # Returns true from inside a callback when objects cannot be added/removed.
    def locked? : Bool
      LibCP.space_is_locked(self)
    end

    # Whenever shapes with collision types *a* and *b* collide,
    # this handler will be used to process the collision events.
    #
    # If wildcard handlers are used with either of the collision types,
    # it's the responibility of the custom handler to invoke the wildcard handlers.
    def add_collision_handler(a : Int, b : Int, handler : CollisionHandler) : CollisionHandler
      @collision_handlers << handler
      handler.prime!(LibCP.space_add_collision_handler(self, a, b))
    end

    # Set a wildcard collision handler for the specified type.
    #
    # This handler will be used any time an object with this type collides
    # with another object, regardless of its type.
    def add_collision_handler(type : Int, handler : CollisionHandler) : CollisionHandler
      @collision_handlers << handler
      handler.prime!(LibCP.space_add_wildcard_handler(self, type))
    end

    # Set a collision handler that is called for all collisions that are not
    # handled by a more specific collision handler.
    def add_collision_handler(handler : CollisionHandler) : CollisionHandler
      @collision_handlers << handler
      handler.prime!(LibCP.space_add_default_collision_handler(self))
    end

    {% for type in %w[Body Shape Constraint] %}
      {% name = type.downcase.id %}
      {% type = type.id %}
      {% if type == "Body" %}
        {% names = "bodies".id %}
      {% else %}
        {% names = name + "s" %}
      {% end %}

      # Add a {{name}} to the simulation.{% if type == "Shape" %}
      #
      # If the collision shape is attached to a static body, it will be added as a static shape.{% end %}
      #
      # If this method is called during a simulation step, the addition will be delayed until the step is finished.
      #
      # Returns the same `{{type}}`, for convenience.
      def add({{name}} : {{type}}) : {{type}}
        if @in_step
          @todo[{{name}}] = true
        else
          LibCP.space_add_{{name}}(self, {{name}})
          @{{names}} << {{name}}
        end
        {{name}}
      end

      # Remove a {{name}} from the simulation.
      #
      # If this method is called during a simulation step, the removal will be delayed until the step is finished.
      def remove({{name}} : {{type}})
        if @in_step
          @todo[{{name}}] = false
        else
          LibCP.space_remove_{{name}}(self, {{name}})
          @{{names}}.delete {{name}}
        end
        nil
      end

      # Test if a {{name}} has been added to the space.
      def contains?({{name}} : {{type}}) : Bool
        @{{names}}.includes? {{name}}
      end

      # Yield each {{name}} in the space.
      def each_{{name}}(&block : {{type}} ->)
        @{{names}}.each do |x|
          yield x
        end
      end

      # Get all the {{names}} that are added to the space.
      getter {{names}} : Set({{type}})
    {% end %}

    # Add multiple items
    def add(*items : Shape | Body | Constraint)
      items.each do |item|
        add item
      end
    end

    # Remove multiple items
    def remove(*items : Shape | Body | Constraint)
      items.each do |item|
        remove item
      end
    end

    # Query the space at a point for shapes within the given distance range.
    #
    # The filter is applied to the query and follows the same rules as the
    # collision detection. Sensor shapes are included. If a *max_distance* of
    # 0 is used, the point must lie inside a shape. Negative *max_distance*
    # is also allowed meaning that the point must be a under a certain
    # depth within a shape to be considered a match.
    _cp_gather point_query : PointQueryInfo,
    def point_query(point : Vect, max_distance : Number = 0, filter : ShapeFilter = ShapeFilter::ALL, &block : PointQueryInfo ->)
      LibCP.space_point_query(self, point, max_distance, filter, ->(shape, point, distance, gradient, data) {
        data.as(typeof(block)*).value.call(PointQueryInfo.new(Shape[shape], point, distance, gradient))
      }, pointerof(block))
    end

    # Query the space at a point and return the nearest shape found.
    #
    # Returns nil if no shapes were found.
    def point_query_nearest(point : Vect, max_distance : Number = 0, filter : ShapeFilter = ShapeFilter::ALL) : PointQueryInfo?
      if LibCP.space_point_query_nearest(self, point, max_distance, filter, out info)
        info
      end
    end

    # Perform a directed line segment query (like a raycast) against the space and yield each shape intersected.
    #
    # The filter is applied to the query and follows the same rules as the
    # collision detection. Sensor shapes are included.
    _cp_gather segment_query : SegmentQueryInfo,
    def segment_query(start : Vect, end end_ : Vect, radius : Number = 0, filter : ShapeFilter = ShapeFilter::ALL, &block : SegmentQueryInfo ->)
      LibCP.space_segment_query(self, start, end_, radius, filter, ->(shape, point, normal, alpha, data) {
        data.as(typeof(block)*).value.call(SegmentQueryInfo.new(Shape[shape], point, normal, alpha))
      }, pointerof(block))
    end

    # Perform a directed line segment query (like a raycast) against the space and return the first shape hit.
    #
    # Returns nil if no shapes were hit.
    def segment_query_first(start : Vect, end end_ : Vect, radius : Number = 0, filter : ShapeFilter = ShapeFilter::ALL) : SegmentQueryInfo?
      if LibCP.space_segment_query_first(self, start, end_, radius, filter, out info)
        info
      end
    end

    # Perform a fast rectangle query on the space, yielding each shape found.
    #
    # Only the shapes' bounding boxes are checked for overlap, not their full shape.
    _cp_gather bb_query : Shape,
    def bb_query(bb : BB, filter : ShapeFilter = ShapeFilter::ALL, &block : Shape ->)
      LibCP.space_bb_query(self, bb, filter, ->(shape, data) {
        data.as(typeof(block)*).value.call(Shape[shape])
      }, pointerof(block))
    end

    # Query a space for any shapes overlapping the given shape and yield each shape found.
    _cp_gather shape_query : Shape,
    def shape_query(shape : Shape, &block : (Shape, ContactPointSet) ->)
      LibCP.space_shape_query(self, shape, ->(shape, contact_point_set, data) {
        data.as(typeof(block)*).value.call(Shape[shape], contact_point_set.value)
      }, pointerof(block))
    end

    # Update the collision detection info for the static shapes in the space.
    def reindex_static()
      LibCP.space_reindex_static(self)
    end

    # Update the collision detection data for a specific shape in the space.
    def reindex(shape : Shape)
      LibCP.space_reindex_shape(self, shape)
    end

    # Update the collision detection data for all shapes attached to a body.
    def reindex_shapes_for(body : Body)
      LibCP.space_reindex_shapes_for_body(self, body)
    end

    # Switch the space to use a spatial has as its spatial index.
    def use_spatial_hash(dim : Number, count : Int)
      LibCP.space_use_spatial_hash(self, dim, count)
    end

    # Step the space forward in time by *dt* seconds.
    def step(dt : Number)
      @in_step = true
      threaded? LibCP.hasty_space_step(self, dt), LibCP.space_step(self, dt)
      @in_step = false

      @todo.each do |item, add|
        if add
          add item
        else
          remove item
        end
      end
      @todo.clear
    end

    # Set number of threads for multithreaded physics solver
    def threads=(nthreads : Int)
      threaded? LibCP.hasty_space_set_threads(self, nthreads), nil
    end

    # Returns number of threads for multithreaded physics solver or 0 if the space isn't hasty
    def threads : Int
      threaded? LibCP.hasty_space_get_threads(self), 0
    end
  end
end
