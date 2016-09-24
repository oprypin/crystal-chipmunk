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


require "./util"

module CP
  @[Extern]
  # A struct that wraps up the important collision data for an arbiter.
  struct ContactPointSet
    @[Extern]
    struct ContactPoint
      # The position of the contact on the surface of each shape.
      getter point_a : Vect, point_b : Vect
      # Penetration distance of the two shapes. Overlapping means it will be negative.
      #
      # This value is calculated as `(point2 - point1).dot(normal)` and is ignored by `contact_point_set=`.
      getter distance : Float64

      def initialize(@point_a : Vect, @point_b : Vect, @distance : Float64)
      end
    end

    # The number of contact points in the set.
    getter count : Int32
    # The normal of the collision.
    getter normal : Vect
    @points : ContactPoint[2]

    def initialize(points : Slice(ContactPoint), @normal : Vect)
      @count = points.size
      @points = uninitialized ContactPoint[2]
      points.copy_to(@points, @count)
    end

    # The contact points.
    def points : Slice(ContactPoint)
      @points.to_unsafe.to_slice(@count)
    end
  end
  # :nodoc:
  alias ContactPoint = ContactPointSet::ContactPoint

  struct Arbiter
    # :nodoc:
    def initialize(@ptr : LibCP::Arbiter*)
    end
    # :nodoc:
    def self.[](ptr : LibCP::Arbiter*) : self
      self.new(ptr)
    end
    # :nodoc:
    def to_unsafe : LibCP::Arbiter*
      @ptr
    end

    # The restitution (elasticity) that will be applied to the pair of colliding objects.
    def restitution : Float64
      LibCP.arbiter_get_restitution(self)
    end
    def restitution=(restitution : Number)
      LibCP.arbiter_set_restitution(self, restitution)
    end

    # The friction coefficient that will be applied to the pair of colliding objects.
    def friction : Float64
      LibCP.arbiter_get_friction(self)
    end
    def friction=(friction : Number)
      LibCP.arbiter_set_friction(self, friction)
    end

    # The relative surface velocity of the two shapes in contact.
    #
    # By default this is calculated to be the difference of the two surface velocities clamped to the tangent plane.
    def surface_velocity : Vect
      LibCP.arbiter_get_surface_velocity(self)
    end
    def surface_velocity=(vr : Vect)
      LibCP.arbiter_set_surface_velocity(self, vr)
    end

    # Calculate the total impulse including the friction that was applied by this arbiter.
    #
    # This function should only be called from a post-solve, post-step or `each_arbiter` callback.
    def total_impulse() : Vect
      LibCP.arbiter_total_impulse(self)
    end

    # Calculate the amount of energy lost in a collision including static, but not dynamic friction.
    #
    # This function should only be called from a post-solve, post-step or `each_arbiter` callback.
    def total_ke() : Float64
      LibCP.arbiter_total_ke(self)
    end

    # Mark a collision pair to be ignored until the two objects separate.
    #
    # Pre-solve and post-solve callbacks will not be called, but the separate callback will be called.
    def ignore() : Bool
      LibCP.arbiter_ignore(self)
    end

    # Return the colliding shapes involved for this arbiter.
    #
    # The order of their `collision_type` values will match
    # the order set when the collision handler was registered.
    def shapes : {Shape, Shape}
      LibCP.arbiter_get_shapes(self, out a, out b)
      {Shape[a], Shape[b]}
    end

    # Return the colliding bodies involved for this arbiter.
    #
    # The order of the `collision_type` the bodies are associated with values will match
    # the order set when the collision handler was registered.
    def bodies : {Body, Body}
      LibCP.arbiter_get_bodies(self, out a, out b)
      {Body[a], Body[b]}
    end

    # Return a contact set from an arbiter.
    def contact_point_set : ContactPointSet
      LibCP.arbiter_get_contact_point_set(self)
    end
    # Replace the contact point set for an arbiter.
    #
    # This can be a very powerful feature, but use it with caution!
    def contact_point_set=(contact_point_set : ContactPointSet)
      LibCP.arbiter_set_contact_point_set(self, pointerof(contact_point_set))
    end

    # Returns true if this is the first step a pair of objects started colliding.
    def first_contact? : Bool
      LibCP.arbiter_is_first_contact(self)
    end

    # Returns true if the separate callback is due to a shape being removed from the space.
    def removal? : Bool
      LibCP.arbiter_is_removal(self)
    end

    # Get the number of contact points for this arbiter.
    def count : Int32
      LibCP.arbiter_get_count(self)
    end

    # Get the normal of the collision.
    def normal() : Vect
      LibCP.arbiter_get_normal(self)
    end

    # Get the position of the *i*-th contact point on the surface of the first shape.
    def point_a(i : Int) : Vect
      LibCP.arbiter_get_point_a(self, i)
    end
    # Get the position of the *i*-th contact point on the surface of the second shape.
    def point_b(i : Int) : Vect
      LibCP.arbiter_get_point_b(self, i)
    end

    # Get the depth of the *i*-th contact point.
    def depth(i : Int) : Float64
      LibCP.arbiter_get_depth(self, i)
    end

    # If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.
    #
    # You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.
    def call_wildcard_begin_a(space : Space) : Bool
      LibCP.arbiter_call_wildcard_begin_a(self, space)
    end
    # If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.
    #
    # You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.
    def call_wildcard_begin_b(space : Space) : Bool
      LibCP.arbiter_call_wildcard_begin_b(self, space)
    end

    # If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.
    #
    # You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.
    def call_wildcard_pre_solve_a(space : Space) : Bool
      LibCP.arbiter_call_wildcard_pre_solve_a(self, space)
    end
    # If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.
    #
    # You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.
    def call_wildcard_pre_solve_b(space : Space) : Bool
      LibCP.arbiter_call_wildcard_pre_solve_b(self, space)
    end

    # If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.
    def call_wildcard_post_solve_a(space : Space)
      LibCP.arbiter_call_wildcard_post_solve_a(self, space)
    end
    # If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.
    def call_wildcard_post_solve_b(space : Space)
      LibCP.arbiter_call_wildcard_post_solve_b(self, space)
    end

    # If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.
    def call_wildcard_separate_a(space : Space)
      LibCP.arbiter_call_wildcard_separate_a(self, space)
    end
    # If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.
    def call_wildcard_separate_b(space : Space)
      LibCP.arbiter_call_wildcard_separate_b(self, space)
    end

    # The user data pointer associated with this pair of colliding objects.
    def data : Void*
      LibCP.arbiter_get_user_data(self)
    end
    def data=(data)
      LibCP.arbiter_set_user_data(self, data.as(Void*))
    end
  end

  # Defines callbacks to configure custom collision handling.
  #
  # Collision handlers have a pair of types; when a collision occurs between two shapes that have these types, the collision handler functions are triggered.
  class CollisionHandler
    alias CollisionType = LibC::SizeT

    # Collision type identifier of the first shape that this handler recognizes.
    #
    # In the collision handler callback, the shape with this type will be the first argument.
    getter type_a = CollisionType.new(0)
    # Collision type identifier of the second shape that this handler recognizes.
    #
    # In the collision handler callback, the shape with this type will be the second argument.
    getter type_b = CollisionType.new(0)

    @@begin : LibCP::CollisionBeginFunc =
    ->(arbiter : LibCP::Arbiter*, space : LibCP::Space*, data : Void*) {
      data.as(self).begin(Arbiter[arbiter], Space[space]).as Bool
    }
    @@pre_solve : LibCP::CollisionPreSolveFunc =
    ->(arbiter : LibCP::Arbiter*, space : LibCP::Space*, data : Void*) {
      data.as(self).pre_solve(Arbiter[arbiter], Space[space]).as Bool
    }
    @@post_solve : LibCP::CollisionPostSolveFunc =
    ->(arbiter : LibCP::Arbiter*, space : LibCP::Space*, data : Void*) {
      data.as(self).post_solve(Arbiter[arbiter], Space[space])
      nil
    }
    @@separate : LibCP::CollisionSeparateFunc =
    ->(arbiter : LibCP::Arbiter*, space : LibCP::Space*, data : Void*) {
      data.as(self).separate(Arbiter[arbiter], Space[space])
      nil
    }

    # :nodoc:
    def prime!(this : LibCP::CollisionHandler*) : self
      @type_a = this.value.type_a
      @type_b = this.value.type_b
      _cp_if_overridden :begin { this.value.begin_func = @@begin }
      _cp_if_overridden :pre_solve { this.value.pre_solve_func = @@pre_solve }
      _cp_if_overridden :post_solve { this.value.post_solve_func = @@post_solve }
      _cp_if_overridden :separate { this.value.separate_func = @@separate }
      this.value.user_data = self.as(Void*)
      self
    end

    # This function is called when two shapes with types that match this collision handler begin colliding.
    #
    # Returning false from a begin callback causes the collision to be ignored until
    # the the separate callback is called when the objects stop colliding.
    def begin(arbiter : Arbiter, space : Space) : Bool
      true
    end
    # This function is called each step when two shapes with types that match this collision handler are colliding.
    #
    # It's called before the collision solver runs so that you can affect a collision's outcome.
    #
    # Returning false from a pre-step callback causes the collision to be ignored until the next step.
    def pre_solve(arbiter : Arbiter, space : Space) : Bool
      true
    end
    # This function is called each step when two shapes with types that match this collision handler are colliding.
    #
    # It's called after the collision solver runs so that you can read back information about the collision to trigger events in your game.
    def post_solve(arbiter : Arbiter, space : Space)
    end
    # This function is called when two shapes with types that match this collision handler stop colliding.
    def separate(arbiter : Arbiter, space : Space)
    end
  end

  # :nodoc:
  alias CollisionType = CollisionHandler::CollisionType
end
