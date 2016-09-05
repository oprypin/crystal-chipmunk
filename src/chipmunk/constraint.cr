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
  abstract class Constraint
    @@pre_solve : LibCP::ConstraintPreSolveFunc =
    ->(constraint : LibCP::Constraint*, space : LibCP::Space*) {
      Constraint[constraint].pre_solve(Space[space])
      nil
    }
    @@post_solve : LibCP::ConstraintPostSolveFunc =
    ->(constraint : LibCP::Constraint*, space : LibCP::Space*) {
      Constraint[constraint].post_solve(Space[space])
      nil
    }

    abstract def to_unsafe : LibCP::Constraint

    # :nodoc:
    def self.[](this : LibCP::Constraint*) : self
      LibCP.constraint_get_user_data(this).as(self)
    end
    # :nodoc:
    def self.[]?(this : LibCP::Constraint*) : self?
      self[this] if this
    end

    def finalize
      LibCP.constraint_destroy(self)
    end

    def space : Space?
      Space[LibCP.constraint_get_space(self)]?
    end

    def body_a : Body
      Body[LibCP.constraint_get_body_a(self)]
    end
    def body_b : Body
      Body[LibCP.constraint_get_body_b(self)]
    end

    def bodies : {Body, Body}
      {body_a, body_b}
    end

    def max_force : Float64
      LibCP.constraint_get_max_force(self)
    end
    def max_force=(max_force : Number)
      LibCP.constraint_set_max_force(self, max_force)
    end

    def error_bias : Float64
      LibCP.constraint_get_error_bias(self)
    end
    def error_bias=(error_bias : Number)
      LibCP.constraint_set_error_bias(self, error_bias)
    end

    def max_bias : Float64
      LibCP.constraint_get_max_bias(self)
    end
    def max_bias=(max_bias : Number)
      LibCP.constraint_set_max_bias(self, max_bias)
    end

    def collide_bodies? : Bool
      LibCP.constraint_get_collide_bodies(self)
    end
    def collide_bodies=(collide_bodies : Bool)
      LibCP.constraint_set_collide_bodies(self, collide_bodies)
    end

    def impulse : Float64
      LibCP.constraint_get_impulse(self)
    end

    def pre_solve(space : Space)
    end
    def post_solve(space : Space)
    end
  end

  class GearJoint < Constraint
    def initialize(a : Body, b : Body, phase : Number, ratio : Number)
      @constraint = uninitialized LibCP::GearJoint
      LibCP.gear_joint_init(pointerof(@constraint), a, b, phase, ratio)
      LibCP.constraint_set_user_data(self, self.as(Void*))
      _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
      _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
    end

    # :nodoc:
    def to_unsafe : LibCP::Constraint*
      pointerof(@constraint).as(LibCP::Constraint*)
    end

    def phase : Float64
      LibCP.gear_joint_get_phase(self)
    end
    def phase=(phase : Number)
      LibCP.gear_joint_set_phase(self, phase)
    end

    def ratio : Float64
      LibCP.gear_joint_get_ratio(self)
    end
    def ratio=(ratio : Number)
      LibCP.gear_joint_set_ratio(self, ratio)
    end
  end

  class GrooveJoint < Constraint
    def initialize(a : Body, b : Body, groove_a : Vect, groove_b : Vect, anchor_b : Vect)
      @constraint = uninitialized LibCP::GrooveJoint
      LibCP.groove_joint_init(pointerof(@constraint), a, b, groove_a, groove_b, anchor_b)
      LibCP.constraint_set_user_data(self, self.as(Void*))
      _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
      _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
    end

    # :nodoc:
    def to_unsafe : LibCP::Constraint*
      pointerof(@constraint).as(LibCP::Constraint*)
    end

    def groove_a : Vect
      LibCP.groove_joint_get_groove_a(self)
    end
    def groove_a=(groove_a : Vect)
      LibCP.groove_joint_set_groove_a(self, groove_a)
    end

    def groove_b : Vect
      LibCP.groove_joint_get_groove_b(self)
    end
    def groove_b=(groove_b : Vect)
      LibCP.groove_joint_set_groove_b(self, groove_b)
    end

    def anchor_b : Vect
      LibCP.groove_joint_get_anchor_b(self)
    end
    def anchor_b=(anchor_b : Vect)
      LibCP.groove_joint_set_anchor_b(self, anchor_b)
    end
  end

  class PinJoint < Constraint
    def initialize(a : Body, b : Body, anchor_a : Vect, anchor_b : Vect)
      @constraint = uninitialized LibCP::PinJoint
      LibCP.pin_joint_init(pointerof(@constraint), a, b, anchor_a, anchor_b)
      LibCP.constraint_set_user_data(self, self.as(Void*))
      _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
      _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
    end

    # :nodoc:
    def to_unsafe : LibCP::Constraint*
      pointerof(@constraint).as(LibCP::Constraint*)
    end

    def anchor_a : Vect
      LibCP.pin_joint_get_anchor_a(self)
    end
    def anchor_a=(anchor_a : Vect)
      LibCP.pin_joint_set_anchor_a(self, anchor_a)
    end

    def anchor_b : Vect
      LibCP.pin_joint_get_anchor_b(self)
    end
    def anchor_b=(anchor_b : Vect)
      LibCP.pin_joint_set_anchor_b(self, anchor_b)
    end

    def dist : Float64
      LibCP.pin_joint_get_dist(self)
    end
    def dist=(dist : Number)
      LibCP.pin_joint_set_dist(self, dist)
    end
  end

  class PivotJoint < Constraint
    def initialize(a : Body, b : Body, anchor_a : Vect, anchor_b : Vect)
      @constraint = uninitialized LibCP::PivotJoint
      LibCP.pivot_joint_init(pointerof(@constraint), a, b, anchor_a, anchor_b)
      LibCP.constraint_set_user_data(self, self.as(Void*))
      _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
      _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
    end
    def self.new(a : Body?, b : Body?, pivot : Vect) : self
      anchor_a = (a ? a.world_to_local(pivot) : pivot)
      anchor_b = (b ? b.world_to_local(pivot) : pivot)
      self.new(a, b, anchor_a, anchor_b)
    end

    # :nodoc:
    def to_unsafe : LibCP::Constraint*
      pointerof(@constraint).as(LibCP::Constraint*)
    end

    def anchor_a : Vect
      LibCP.pivot_joint_get_anchor_a(self)
    end
    def anchor_a=(anchor_a : Vect)
      LibCP.pivot_joint_set_anchor_a(self, anchor_a)
    end

    def anchor_b : Vect
      LibCP.pivot_joint_get_anchor_b(self)
    end
    def anchor_b=(anchor_b : Vect)
      LibCP.pivot_joint_set_anchor_b(self, anchor_b)
    end
  end

  class SlideJoint < Constraint
    def initialize(a : Body, b : Body, anchor_a : Vect, anchor_b : Vect, min : Number, max : Number)
      @constraint = uninitialized LibCP::SlideJoint
      LibCP.slide_joint_init(pointerof(@constraint), a, b, anchor_a, anchor_b, min, max)
      LibCP.constraint_set_user_data(self, self.as(Void*))
      _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
      _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
    end

    # :nodoc:
    def to_unsafe : LibCP::Constraint*
      pointerof(@constraint).as(LibCP::Constraint*)
    end

    def anchor_a : Vect
      LibCP.slide_joint_get_anchor_a(self)
    end
    def anchor_a=(anchor_a : Vect)
      LibCP.slide_joint_set_anchor_a(self, anchor_a)
    end

    def anchor_b : Vect
      LibCP.slide_joint_get_anchor_b(self)
    end
    def anchor_b=(anchor_b : Vect)
      LibCP.slide_joint_set_anchor_b(self, anchor_b)
    end

    def min : Float64
      LibCP.slide_joint_get_min(self)
    end
    def min=(min : Number)
      LibCP.slide_joint_set_min(self, min)
    end

    def max : Float64
      LibCP.slide_joint_get_max(self)
    end
    def max=(max : Number)
      LibCP.slide_joint_set_max(self, max)
    end
  end

  class RatchetJoint < Constraint
    def initialize(a : Body, b : Body, phase : Number, ratchet : Number)
      @constraint = uninitialized LibCP::RatchetJoint
      LibCP.ratchet_joint_init(pointerof(@constraint), a, b, phase, ratchet)
      LibCP.constraint_set_user_data(self, self.as(Void*))
      _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
      _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
    end

    # :nodoc:
    def to_unsafe : LibCP::Constraint*
      pointerof(@constraint).as(LibCP::Constraint*)
    end

    def angle : Float64
      LibCP.ratchet_joint_get_angle(self)
    end
    def angle=(angle : Number)
      LibCP.ratchet_joint_set_angle(self, angle)
    end

    def phase : Float64
      LibCP.ratchet_joint_get_phase(self)
    end
    def phase=(phase : Number)
      LibCP.ratchet_joint_set_phase(self, phase)
    end

    def ratchet : Float64
      LibCP.ratchet_joint_get_ratchet(self)
    end
    def ratchet=(ratchet : Number)
      LibCP.ratchet_joint_set_ratchet(self, ratchet)
    end
  end

  class RotaryLimitJoint < Constraint
    def initialize(a : Body, b : Body, min : Number, max : Number)
      @constraint = uninitialized LibCP::RotaryLimitJoint
      LibCP.rotary_limit_joint_init(pointerof(@constraint), a, b, min, max)
      LibCP.constraint_set_user_data(self, self.as(Void*))
      _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
      _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
    end

    # :nodoc:
    def to_unsafe : LibCP::Constraint*
      pointerof(@constraint).as(LibCP::Constraint*)
    end

    def min : Float64
      LibCP.rotary_limit_joint_get_min(self)
    end
    def min=(min : Number)
      LibCP.rotary_limit_joint_set_min(self, min)
    end

    def max : Float64
      LibCP.rotary_limit_joint_get_max(self)
    end
    def max=(max : Number)
      LibCP.rotary_limit_joint_set_max(self, max)
    end
  end

  class DampedSpring < Constraint
    @@spring_force : LibCP::DampedSpringForceFunc =
    ->(constraint : LibCP::Constraint*, dist : Float64) {
      DampedSpring[constraint].spring_force(dist).to_f
    }

    def initialize(a : Body, b : Body, anchor_a : Vect, anchor_b : Vect, rest_length : Number, stiffness : Number, damping : Number)
      @constraint = uninitialized LibCP::DampedSpring
      LibCP.damped_spring_init(pointerof(@constraint), a, b, anchor_a, anchor_b, rest_length, stiffness, damping)
      LibCP.constraint_set_user_data(self, self.as(Void*))
      _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
      _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
      _cp_if_overridden :spring_force { LibCP.damped_spring_set_spring_force_func(self, @@spring_force) }
    end

    # :nodoc:
    def to_unsafe : LibCP::Constraint*
      pointerof(@constraint).as(LibCP::Constraint*)
    end

    def anchor_a : Vect
      LibCP.damped_spring_get_anchor_a(self)
    end
    def anchor_a=(anchor_a : Vect)
      LibCP.damped_spring_set_anchor_a(self, anchor_a)
    end

    def anchor_b : Vect
      LibCP.damped_spring_get_anchor_b(self)
    end
    def anchor_b=(anchor_b : Vect)
      LibCP.damped_spring_set_anchor_b(self, anchor_b)
    end

    def rest_length : Float64
      LibCP.damped_spring_get_rest_length(self)
    end
    def rest_length=(rest_length : Number)
      LibCP.damped_spring_set_rest_length(self, rest_length)
    end

    def stiffness : Float64
      LibCP.damped_spring_get_stiffness(self)
    end
    def stiffness=(stiffness : Number)
      LibCP.damped_spring_set_stiffness(self, stiffness)
    end

    def damping : Float64
      LibCP.damped_spring_get_damping(self)
    end
    def damping=(damping : Number)
      LibCP.damped_spring_set_damping(self, damping)
    end

    def spring_force(dist : Float64) : Number
      0
    end
  end

  class DampedRotarySpring < Constraint
    @@spring_torque : LibCP::DampedRotarySpringTorqueFunc =
    ->(constraint : LibCP::Constraint*, relative_angle : Float64) {
      DampedRotarySpring[constraint].spring_torque(relative_angle).to_f
    }

    def initialize(a : Body, b : Body, rest_angle : Number, stiffness : Number, damping : Number)
      @constraint = uninitialized LibCP::DampedRotarySpring
      LibCP.damped_rotary_spring_init(pointerof(@constraint), a, b, rest_angle, stiffness, damping)
      LibCP.constraint_set_user_data(self, self.as(Void*))
      _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
      _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
      _cp_if_overridden :spring_torque { LibCP.damped_rotary_spring_set_spring_torque_func(self, @@spring_torque) }
    end

    # :nodoc:
    def to_unsafe : LibCP::Constraint*
      pointerof(@constraint).as(LibCP::Constraint*)
    end

    def rest_angle : Float64
      LibCP.damped_rotary_spring_get_rest_angle(self)
    end
    def rest_angle=(rest_angle : Number)
      LibCP.damped_rotary_spring_set_rest_angle(self, rest_angle)
    end

    def stiffness : Float64
      LibCP.damped_rotary_spring_get_stiffness(self)
    end
    def stiffness=(stiffness : Number)
      LibCP.damped_rotary_spring_set_stiffness(self, stiffness)
    end

    def damping : Float64
      LibCP.damped_rotary_spring_get_damping(self)
    end
    def damping=(damping : Number)
      LibCP.damped_rotary_spring_set_damping(self, damping)
    end

    def spring_torque(relative_angle : Float64) : Number
      0
    end
  end

  class SimpleMotor < Constraint
    def initialize(a : Body, b : Body, rate : Number)
      @constraint = uninitialized LibCP::SimpleMotor
      LibCP.simple_motor_init(pointerof(@constraint), a, b, rate)
      LibCP.constraint_set_user_data(self, self.as(Void*))
      _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
      _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
    end

    # :nodoc:
    def to_unsafe : LibCP::Constraint*
      pointerof(@constraint).as(LibCP::Constraint*)
    end

    def rate : Float64
      LibCP.simple_motor_get_rate(self)
    end
    def rate=(rate : Number)
      LibCP.simple_motor_set_rate(self, rate)
    end
  end
end
