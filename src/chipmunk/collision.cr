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

    def restitution : Float64
      LibCP.arbiter_get_restitution(self)
    end
    def restitution=(restitution : Number)
      LibCP.arbiter_set_restitution(self, restitution)
    end

    def friction : Float64
      LibCP.arbiter_get_friction(self)
    end
    def friction=(friction : Number)
      LibCP.arbiter_set_friction(self, friction)
    end

    def total_impulse() : Vect
      LibCP.arbiter_total_impulse(self)
    end

    def total_ke() : Float64
      LibCP.arbiter_total_ke(self)
    end

    def ignore() : Bool
      LibCP.arbiter_ignore(self)
    end

    def shapes : {Shape, Shape}
      LibCP.arbiter_get_shapes(self, out a, out b)
      {Shape[a], Shape[b]}
    end
    def bodies : {Body, Body}
      LibCP.arbiter_get_bodies(self, out a, out b)
      {Body[a], Body[b]}
    end

    def contact_point_set : ContactPointSet
      LibCP.arbiter_get_contact_point_set(self)
    end
    def contact_point_set=(contact_point_set : ContactPointSet)
      LibCP.arbiter_set_contact_point_set(self, contact_point_set)
    end

    def first_contact? : Bool
      LibCP.arbiter_is_first_contact(self)
    end

    def removal? : Bool
      LibCP.arbiter_is_removal(self)
    end

    def count : Int32
      LibCP.arbiter_get_count(self)
    end

    def normal() : Vect
      LibCP.arbiter_get_normal(self)
    end

    def point_a(i : Int) : Vect
      LibCP.arbiter_get_point_a(self, i)
    end
    def point_b(i : Int) : Vect
      LibCP.arbiter_get_point_b(self, i)
    end

    def depth(i : Int) : Float64
      LibCP.arbiter_get_depth(self, i)
    end

    def call_wildcard_begin_a(space : Space) : Bool
      arbiter_call_wildcard_begin_a(self, space)
    end
    def call_wildcard_begin_b(space : Space) : Bool
      arbiter_call_wildcard_begin_b(self, space)
    end

    def call_wildcard_pre_solve_a(space : Space) : Bool
      arbiter_call_wildcard_pre_solve_a(self, space)
    end
    def call_wildcard_pre_solve_b(space : Space) : Bool
      arbiter_call_wildcard_pre_solve_b(self, space)
    end

    def call_wildcard_post_solve_a(space : Space)
      arbiter_call_wildcard_post_solve_a(self, space)
    end
    def call_wildcard_post_solve_b(space : Space)
      arbiter_call_wildcard_post_solve_b(self, space)
    end

    def call_wildcard_separate_a(space : Space)
      arbiter_call_wildcard_separate_a(self, space)
    end
    def call_wildcard_separate_b(space : Space)
      arbiter_call_wildcard_separate_b(self, space)
    end
  end

  class CollisionHandler
    getter type_a = CollisionType.new(0)
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

    def begin(arbiter : Arbiter, space : Space) : Bool
      true
    end
    def pre_solve(arbiter : Arbiter, space : Space) : Bool
      true
    end
    def post_solve(arbiter : Arbiter, space : Space)
    end
    def separate(arbiter : Arbiter, space : Space)
    end
  end
end
