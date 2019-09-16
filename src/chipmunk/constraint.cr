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
  # A constraint is something that describes how two bodies interact with
  # each other (how they constrain each other). Constraints can be simple
  # joints that allow bodies to pivot around each other like the bones in your
  # body, or they can be more abstract like the gear joint or motors.
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

    # :nodoc:
    abstract def to_unsafe : LibCP::Constraint*

    # :nodoc:
    def self.[](this : LibCP::Constraint*) : self
      LibCP.constraint_get_user_data(this).as(self)
    end
    # :nodoc:
    def self.[]?(this : LibCP::Constraint*) : self?
      self[this] if this
    end

    # Avoid a finalization cycle; cpConstraintDestroy is empty anyway
    #def finalize
      #LibCP.constraint_destroy(self)
    #end

    # Get the `Space` this constraint is added to.
    def space : Space?
      Space[LibCP.constraint_get_space(self)]?
    end

    # Get the first body the constraint is attached to.
    def body_a : Body
      Body[LibCP.constraint_get_body_a(self)]
    end
    # Get the second body the constraint is attached to.
    def body_b : Body
      Body[LibCP.constraint_get_body_b(self)]
    end

    # Get the bodies the constraint is attached to.
    def bodies : {Body, Body}
      {body_a, body_b}
    end

    # The maximum force that this constraint is allowed to use.
    #
    # (defaults to INFINITY)
    def max_force : Float64
      LibCP.constraint_get_max_force(self)
    end
    def max_force=(max_force : Number)
      LibCP.constraint_set_max_force(self, max_force)
    end

    # Rate at which joint error is corrected.
    #
    # Defaults to (1.0 - 0.1) ** 60.0 meaning that it will
    # correct 10% of the error every 1/60th of a second.
    def error_bias : Float64
      LibCP.constraint_get_error_bias(self)
    end
    def error_bias=(error_bias : Number)
      LibCP.constraint_set_error_bias(self, error_bias)
    end

    # The maximum rate at which joint error is corrected.
    #
    # (defaults to INFINITY)
    def max_bias : Float64
      LibCP.constraint_get_max_bias(self)
    end
    def max_bias=(max_bias : Number)
      LibCP.constraint_set_max_bias(self, max_bias)
    end

    # Are the two bodies connected by the constraint allowed to collide or not?
    #
    # (defaults to false)
    def collide_bodies? : Bool
      LibCP.constraint_get_collide_bodies(self)
    end
    def collide_bodies=(collide_bodies : Bool)
      LibCP.constraint_set_collide_bodies(self, collide_bodies)
    end

    # Get the most recent impulse applied by this constraint.
    #
    # To convert this to a force, divide by the timestep passed to
    # `Space#step`. You can use this to implement breakable joints to check
    # if the force they attempted to apply exceeded a certain threshold.
    def impulse : Float64
      LibCP.constraint_get_impulse(self)
    end

    # The pre-solve method that is called before the solver runs
    # (can be overridden in a subclass).
    def pre_solve(space : Space)
    end
    # The post-solve method that is called before the solver runs
    # (can be overridden in a subclass).
    def post_solve(space : Space)
    end

    # Keeps the angular velocity ratio of a pair of bodies constant.
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

      # The phase offset of the gears.
      def phase : Float64
        LibCP.gear_joint_get_phase(self)
      end
      def phase=(phase : Number)
        LibCP.gear_joint_set_phase(self, phase)
      end

      # The angular distance of each ratchet.
      def ratio : Float64
        LibCP.gear_joint_get_ratio(self)
      end
      def ratio=(ratio : Number)
        LibCP.gear_joint_set_ratio(self, ratio)
      end
    end

    # Similar to a pivot joint, but one of the anchors is
    # on a linear slide instead of being fixed.
    class GrooveJoint < Constraint
      # The groove goes from *groove_a* to *groove_b* on body *a*, and the pivot
      # is attached to *anchor_b* on body *b*.
      #
      # All coordinates are body local.
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

      # The first endpoint of the groove relative to the first body.
      def groove_a : Vect
        LibCP.groove_joint_get_groove_a(self)
      end
      def groove_a=(groove_a : Vect)
        LibCP.groove_joint_set_groove_a(self, groove_a)
      end

      # The second endpoint of the groove relative to the second body.
      def groove_b : Vect
        LibCP.groove_joint_get_groove_b(self)
      end
      def groove_b=(groove_b : Vect)
        LibCP.groove_joint_set_groove_b(self, groove_b)
      end

      # The location of the second anchor relative to the second body.
      def anchor_b : Vect
        LibCP.groove_joint_get_anchor_b(self)
      end
      def anchor_b=(anchor_b : Vect)
        LibCP.groove_joint_set_anchor_b(self, anchor_b)
      end
    end

    # Keeps the anchor points at a set distance from one another.
    class PinJoint < Constraint
      # *a* and *b* are the two bodies to connect, and *anchor_a* and *anchor_b*
      # arethe anchor points on those bodies.
      #
      # The distance between the two anchor points is measured when the joint
      # is created. If you want to set a specific distance, use the setter
      # function to override it.
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

      # The location of the first anchor relative to the first body.
      def anchor_a : Vect
        LibCP.pin_joint_get_anchor_a(self)
      end
      def anchor_a=(anchor_a : Vect)
        LibCP.pin_joint_set_anchor_a(self, anchor_a)
      end

      # The location of the second anchor relative to the second body.
      def anchor_b : Vect
        LibCP.pin_joint_get_anchor_b(self)
      end
      def anchor_b=(anchor_b : Vect)
        LibCP.pin_joint_set_anchor_b(self, anchor_b)
      end

      # The distance the joint will maintain between the two anchors.
      def dist : Float64
        LibCP.pin_joint_get_dist(self)
      end
      def dist=(dist : Number)
        LibCP.pin_joint_set_dist(self, dist)
      end
    end

    # Allows two objects to pivot about a single point.
    class PivotJoint < Constraint
      # *a* and *b* are the two bodies to connect, and *anchor_a* and *anchor_b*
      # are the points in local coordinates where the pivot is located.
      def initialize(a : Body, b : Body, anchor_a : Vect, anchor_b : Vect)
        @constraint = uninitialized LibCP::PivotJoint
        LibCP.pivot_joint_init(pointerof(@constraint), a, b, anchor_a, anchor_b)
        LibCP.constraint_set_user_data(self, self.as(Void*))
        _cp_if_overridden :pre_solve { LibCP.constraint_set_pre_solve_func(self, @@pre_solve) }
        _cp_if_overridden :post_solve { LibCP.constraint_set_post_solve_func(self, @@post_solve) }
      end
      # *a* and *b* are the two bodies to connect, and *pivot* is the point in
      # world coordinates of the pivot.
      def self.new(a : Body, b : Body, pivot : Vect) : self
        anchor_a = a.world_to_local(pivot)
        anchor_b = b.world_to_local(pivot)
        self.new(a, b, anchor_a, anchor_b)
      end

      # :nodoc:
      def to_unsafe : LibCP::Constraint*
        pointerof(@constraint).as(LibCP::Constraint*)
      end

      # The location of the first anchor relative to the first body.
      def anchor_a : Vect
        LibCP.pivot_joint_get_anchor_a(self)
      end
      def anchor_a=(anchor_a : Vect)
        LibCP.pivot_joint_set_anchor_a(self, anchor_a)
      end

      # The location of the second anchor relative to the second body.
      def anchor_b : Vect
        LibCP.pivot_joint_get_anchor_b(self)
      end
      def anchor_b=(anchor_b : Vect)
        LibCP.pivot_joint_set_anchor_b(self, anchor_b)
      end
    end

    # Like pin joints, but have a minimum and maximum distance.
    # A chain could be modeled using this joint. It keeps the anchor points
    # from getting too far apart, but will allow them to get closer together.
    class SlideJoint < Constraint
      # *a* and *b* are the two bodies to connect, *anchor_a* and *anchor_b* are
      # the anchor points on those bodies, and *min* and *max* define the allowed
      # distances of the anchor points.
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

      # The location of the first anchor relative to the first body.
      def anchor_a : Vect
        LibCP.slide_joint_get_anchor_a(self)
      end
      def anchor_a=(anchor_a : Vect)
        LibCP.slide_joint_set_anchor_a(self, anchor_a)
      end

      # The location of the second anchor relative to the second body.
      def anchor_b : Vect
        LibCP.slide_joint_get_anchor_b(self)
      end
      def anchor_b=(anchor_b : Vect)
        LibCP.slide_joint_set_anchor_b(self, anchor_b)
      end

      # The minimum distance the joint will maintain between the two anchors.
      def min : Float64
        LibCP.slide_joint_get_min(self)
      end
      def min=(min : Number)
        LibCP.slide_joint_set_min(self, min)
      end

      # The maximum distance the joint will maintain between the two anchors.
      def max : Float64
        LibCP.slide_joint_get_max(self)
      end
      def max=(max : Number)
        LibCP.slide_joint_set_max(self, max)
      end
    end

    # Works like a socket wrench.
    class RatchetJoint < Constraint
      # *ratchet* is the distance between "clicks", *phase* is the initial offset
      # to use when deciding where the ratchet angles are.
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

      # The angle of the current ratchet tooth.
      def angle : Float64
        LibCP.ratchet_joint_get_angle(self)
      end
      def angle=(angle : Number)
        LibCP.ratchet_joint_set_angle(self, angle)
      end

      # The phase offset of the ratchet.
      def phase : Float64
        LibCP.ratchet_joint_get_phase(self)
      end
      def phase=(phase : Number)
        LibCP.ratchet_joint_set_phase(self, phase)
      end

      # The angular distance of each ratchet.
      def ratchet : Float64
        LibCP.ratchet_joint_get_ratchet(self)
      end
      def ratchet=(ratchet : Number)
        LibCP.ratchet_joint_set_ratchet(self, ratchet)
      end
    end

    # Constrains the relative rotations of two bodies.
    class RotaryLimitJoint < Constraint
      # *min* and *max* are the angular limits in radians. It is implemented so
      # that it's possible to for the range to be greater than a full revolution.
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

      # The minimum distance the joint will maintain between the two anchors.
      def min : Float64
        LibCP.rotary_limit_joint_get_min(self)
      end
      def min=(min : Number)
        LibCP.rotary_limit_joint_set_min(self, min)
      end

      # The maximum distance the joint will maintain between the two anchors.
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

      # Defined much like a slide joint.
      #
      # * *anchor_a*: Anchor point a, relative to body a
      # * *anchor_b*: Anchor point b, relative to body b
      # * *rest_length*: The distance the spring wants to be at
      # * *stiffness*: The spring constant (Young's modulus)
      # * *damping*: How soft to make the damping of the spring
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

      # The location of the first anchor relative to the first body.
      def anchor_a : Vect
        LibCP.damped_spring_get_anchor_a(self)
      end
      def anchor_a=(anchor_a : Vect)
        LibCP.damped_spring_set_anchor_a(self, anchor_a)
      end

      # The location of the second anchor relative to the second body.
      def anchor_b : Vect
        LibCP.damped_spring_get_anchor_b(self)
      end
      def anchor_b=(anchor_b : Vect)
        LibCP.damped_spring_set_anchor_b(self, anchor_b)
      end

      # The distance the spring wants to be at.
      def rest_length : Float64
        LibCP.damped_spring_get_rest_length(self)
      end
      def rest_length=(rest_length : Number)
        LibCP.damped_spring_set_rest_length(self, rest_length)
      end

      # The stiffness of the spring in force/distance.
      def stiffness : Float64
        LibCP.damped_spring_get_stiffness(self)
      end
      def stiffness=(stiffness : Number)
        LibCP.damped_spring_set_stiffness(self, stiffness)
      end

      # How soft to make the damping of the spring.
      def damping : Float64
        LibCP.damped_spring_get_damping(self)
      end
      def damping=(damping : Number)
        LibCP.damped_spring_set_damping(self, damping)
      end

      # (can be overridden in a subclass)
      def spring_force(dist : Float64) : Number
        0
      end
    end

    # Like a damped spring, but works in an angular fashion
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

      # The relative angle in radians that the bodies want to have
      def rest_angle : Float64
        LibCP.damped_rotary_spring_get_rest_angle(self)
      end
      def rest_angle=(rest_angle : Number)
        LibCP.damped_rotary_spring_set_rest_angle(self, rest_angle)
      end

      # The stiffness of the spring in force/distance.
      def stiffness : Float64
        LibCP.damped_rotary_spring_get_stiffness(self)
      end
      def stiffness=(stiffness : Number)
        LibCP.damped_rotary_spring_set_stiffness(self, stiffness)
      end

      # How soft to make the damping of the spring.
      def damping : Float64
        LibCP.damped_rotary_spring_get_damping(self)
      end
      def damping=(damping : Number)
        LibCP.damped_rotary_spring_set_damping(self, damping)
      end

      # (can be overridden in a subclass)
      def spring_torque(relative_angle : Float64) : Number
        0
      end
    end

    # Keeps the relative angular velocity of a pair of bodies constant.
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

      # The desired relative angular velocity of the motor.
      #
      # You will usually want to set a force (torque) maximum for motors as otherwise
      # they will be able to apply a nearly infinite torque to keep the bodies moving.
      def rate : Float64
        LibCP.simple_motor_get_rate(self)
      end
      def rate=(rate : Number)
        LibCP.simple_motor_set_rate(self, rate)
      end
    end
  end

  # :nodoc:
  alias GearJoint = Constraint::GearJoint
  # :nodoc:
  alias GrooveJoint = Constraint::GrooveJoint
  # :nodoc:
  alias PinJoint = Constraint::PinJoint
  # :nodoc:
  alias PivotJoint = Constraint::PivotJoint
  # :nodoc:
  alias SlideJoint = Constraint::SlideJoint
  # :nodoc:
  alias RatchetJoint = Constraint::RatchetJoint
  # :nodoc:
  alias RotaryLimitJoint = Constraint::RotaryLimitJoint
  # :nodoc:
  alias DampedSpring = Constraint::DampedSpring
  # :nodoc:
  alias DampedRotarySpring = Constraint::DampedRotarySpring
  # :nodoc:
  alias SimpleMotor = Constraint::SimpleMotor
  # Extracting with macros causes a bug :(
end
