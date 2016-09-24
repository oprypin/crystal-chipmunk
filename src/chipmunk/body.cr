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
  # Chipmunk's rigid body type.
  #
  # Rigid bodies hold the physical properties of an object like its mass, and position and velocity
  # of its center of gravity. They don't have an shape on their own.
  # They are given a shape by creating collision shapes (`Shape`) that point to the body.
  class Body
    enum Type
      # A dynamic body is one that is affected by gravity, forces, and collisions.
      # This is the default body type.
      DYNAMIC
      # A kinematic body is an infinite mass, user controlled body that is not affected by gravity, forces or collisions.
      # Instead the body only moves based on it's velocity.
      # Dynamic bodies collide normally with kinematic bodies, though the kinematic body will be unaffected.
      # Collisions between two kinematic bodies, or a kinematic body and a static body produce collision callbacks, but no collision response.
      KINEMATIC
      # A static body is a body that never (or rarely) moves. If you move a static body, you must call one of the `Space` reindex functions.
      # Chipmunk uses this information to optimize the collision detection.
      # Static bodies do not produce collision callbacks when colliding with other static bodies.
      STATIC
    end
    # :nodoc:
    DYNAMIC = Type::DYNAMIC
    # :nodoc:
    KINEMATIC = Type::KINEMATIC
    # :nodoc:
    STATIC = Type::STATIC

    @@update_velocity : LibCP::BodyVelocityFunc = ->(body : LibCP::Body*, gravity : Vect, damping : Float64, dt : Float64) {
      Body[body].update_velocity(gravity, damping, dt)
      nil
    }
    @@update_position : LibCP::BodyPositionFunc = ->(body : LibCP::Body*, dt : Float64) {
      Body[body].update_position(dt)
      nil
    }

    def initialize(mass : Number = 0, moment : Number = 0)
      @body = uninitialized LibCP::Body
      LibCP.body_init(self, mass, moment)
      LibCP.body_set_user_data(self, self.as(Void*))
      _cp_if_overridden :update_velocity { LibCP.body_set_velocity_update_func(self, @@update_velocity) }
      _cp_if_overridden :update_position { LibCP.body_set_position_update_func(self, @@update_position) }
    end

    # Allocate and initialize a `Body`, and set it as a kinematic body.
    def self.new_kinematic() : self
      body = self.new
      body.type = Type::KINEMATIC
      body
    end
    # Allocate and initialize a `Body`, and set it as a static body.
    def self.new_static() : self
      body = self.new
      body.type = Type::STATIC
      body
    end

    # :nodoc:
    def to_unsafe : LibCP::Body*
      pointerof(@body)
    end
    # :nodoc:
    def self.[](this : LibCP::Body*) : self
      LibCP.body_get_user_data(this).as(self)
    end
    # :nodoc:
    def self.[]?(this : LibCP::Body*) : self?
      self[this] if this
    end

    def finalize
      LibCP.body_destroy(self)
    end

    # Wake up a sleeping or idle body.
    def activate()
      LibCP.body_activate(self)
    end
    # Wake up any sleeping or idle bodies touching a static body.
    def activate_static(filter : Shape?)
      LibCP.body_activate_static(self, filter)
    end

    # Force a body to fall asleep immediately.
    def sleep()
      raise "Body not added to space" if !LibCP.body_get_space(self)
      LibCP.body_sleep(self)
    end
    # Force a body to fall asleep immediately along with other bodies in a group.
    def sleep_with_group(group : Body)
      raise "Body not added to space" if !LibCP.body_get_space(self)
      LibCP.body_sleep_with_group(self, group)
    end

    # Returns true if the body is sleeping.
    def sleeping? : Bool
      LibCP.body_is_sleeping(self)
    end

    # The type of the body.
    def type : Type
      LibCP.body_get_type(self)
    end
    def type=(type : Type)
      LibCP.body_set_type(self, type)
    end

    # Get the space this body is added to.
    def space : Space?
      Space[LibCP.body_get_space(self)]?
    end

    # The mass of the body.
    def mass : Float64
      LibCP.body_get_mass(self)
    end
    def mass=(mass : Number)
      LibCP.body_set_mass(self, mass)
    end

    # The moment of inertia of the body.
    def moment : Float64
      LibCP.body_get_moment(self)
    end
    def moment=(moment : Number)
      LibCP.body_set_moment(self, moment)
    end

    # The position of a body.
    def position : Vect
      LibCP.body_get_position(self)
    end
    def position=(position : Vect)
      LibCP.body_set_position(self, position)
    end

    # The offset of the center of gravity in body local coordinates.
    def center_of_gravity : Vect
      LibCP.body_get_center_of_gravity(self)
    end
    def center_of_gravity=(center_of_gravity : Vect)
      LibCP.body_set_center_of_gravity(self, center_of_gravity)
    end

    # The velocity of the body.
    def velocity : Vect
      LibCP.body_get_velocity(self)
    end
    def velocity=(velocity : Vect)
      LibCP.body_set_velocity(self, velocity)
    end

    # The force applied to the body for the next time step.
    def force : Vect
      LibCP.body_get_force(self)
    end
    def force=(force : Vect)
      LibCP.body_set_force(self, force)
    end

    # The angle of the body.
    def angle : Float64
      LibCP.body_get_angle(self)
    end
    def angle=(angle : Number)
      LibCP.body_set_angle(self, angle)
    end

    # The angular velocity of the body.
    def angular_velocity : Float64
      LibCP.body_get_angular_velocity(self)
    end
    def angular_velocity=(angular_velocity : Number)
      LibCP.body_set_angular_velocity(self, angular_velocity)
    end

    # The torque applied to the body for the next time step.
    def torque : Float64
      LibCP.body_get_torque(self)
    end
    def torque=(torque : Number)
      LibCP.body_set_torque(self, torque)
    end

    # Get the rotation vector of the body. (The x basis vector of its transform.)
    def rotation : Vect
      LibCP.body_get_rotation(self)
    end

    # Convert body relative/local coordinates to absolute/world coordinates.
    def local_to_world(point : Vect) : Vect
      LibCP.body_local_to_world(self, point)
    end
    # Convert body absolute/world coordinates to  relative/local coordinates.
    def world_to_local(point : Vect) : Vect
      LibCP.body_world_to_local(self, point)
    end

    # Apply a force to a body. Both the force and point are expressed in world coordinates.
    def apply_force_at_world_point(force : Vect, point : Vect)
      LibCP.body_apply_force_at_world_point(self, force, point)
    end
    # Apply a force to a body. Both the force and point are expressed in body local coordinates.
    def apply_force_at_local_point(force : Vect, point : Vect)
      LibCP.body_apply_force_at_local_point(self, force, point)
    end

    # Apply an impulse to a body. Both the impulse and point are expressed in world coordinates.
    def apply_impulse_at_world_point(impulse : Vect, point : Vect)
      LibCP.body_apply_impulse_at_world_point(self, impulse, point)
    end
    # Apply an impulse to a body. Both the impulse and point are expressed in body local coordinates.
    def apply_impulse_at_local_point(impulse : Vect, point : Vect)
      LibCP.body_apply_impulse_at_local_point(self, impulse, point)
    end

    # Get the velocity on a body (in world units) at a point on the body in world coordinates.
    def velocity_at_world_point(point : Vect) : Vect
      LibCP.body_get_velocity_at_world_point(self, point)
    end
    # Get the velocity on a body (in world units) at a point on the body in local coordinates.
    def velocity_at_local_point(point : Vect) : Vect
      LibCP.body_get_velocity_at_local_point(self, point)
    end

    # Get the amount of kinetic energy contained by the body.
    def kinetic_energy : Float64
      LibCP.body_kinetic_energy(self)
    end

    {% for type in %w[Shape Constraint Arbiter] %}
      {% name = type.downcase.id %}
      {% type = type.id %}

      # Get each {{name}} associated with this body.
      _cp_gather {{name}}s : {{type}},
      def each_{{name}}(&block : {{type}} ->)
        LibCP.body_each_{{name}}(self, ->(body, item, data) {
          data.as(typeof(block)*).value.call({{type}}[item])
        }, pointerof(block))
      end
    {% end %}

    # Used to update a body's velocity (can be overridden in a subclass).
    def update_velocity(gravity : Vect, damping : Number, dt : Number)
      LibCP.body_update_velocity(self, gravity, damping, dt)
    end
    # Used to update a body's position (can be overridden in a subclass).
    #
    # NOTE: It's not generally recommended to override this unless you call `super`.
    def update_position(dt : Number)
      LibCP.body_update_position(self, dt)
    end
  end
end
