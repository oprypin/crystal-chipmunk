class CP::Space
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

  def step(dt : Number)
    LibCP.space_step(self, dt)
  end
end
