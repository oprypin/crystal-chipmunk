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
  class Body
    enum Type
      DYNAMIC
      KINEMATIC
      STATIC
    end
    DYNAMIC = Type::DYNAMIC
    KINEMATIC = Type::KINEMATIC
    STATIC = Type::STATIC

    def initialize(mass : Number = 0, moment : Number = 0)
      @body = uninitialized LibCP::Body
      LibCP.body_init(self, mass, moment)
      LibCP.body_set_user_data(self, self.as(Void*))
    end

    def self.new_kinematic() : self
      body = self.new
      body.type = Type::KINEMATIC
      body
    end
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

    def activate()
      LibCP.body_activate(self)
    end

    def activate_static(filter : Shape?)
      LibCP.body_activate_static(self, filter)
    end

    def sleep()
      raise "Body not added to space" if !LibCP.body_get_space(self)
      LibCP.body_sleep(self)
    end
    def sleep_with_group(group : Body?)
      raise "Body not added to space" if !LibCP.body_get_space(self)
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
      Space[LibCP.body_get_space(self)]?
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
      LibCP.body_set_torque(self, torque)
    end

    def rotation : Vect
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

    def velocity_at_world_point(point : Vect) : Vect
      LibCP.body_get_velocity_at_world_point(self, point)
    end
    def velocity_at_local_point(point : Vect) : Vect
      LibCP.body_get_velocity_at_local_point(self, point)
    end

    def kinetic_energy : Float64
      LibCP.body_kinetic_energy(self)
    end

    {% for type in %w[Shape Constraint Arbiter] %}
      {% name = type.downcase.id %}
      {% type = type.id %}

      _cp_gather {{name}}s : {{type}},
      def each_{{name}}(&block : {{type}} ->)
        LibCP.body_each_{{name}}(self, ->(body, item, data) {
          data.as(typeof(block)*).value.call({{type}}[item])
        }, pointerof(block))
      end
    {% end %}
  end
end
