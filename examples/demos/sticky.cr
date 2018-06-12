# Copyright (c) 2007 Scott Lembcke
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


require "../demo"

class Sticky < Demo
  TITLE = "Sticky Surfaces"

  COLLISION_TYPE_STICKY = 1
  STICK_SENSOR_THICKNESS = 2.5

  def initialize(window)
    super

    random = Random.new

    space = @space
    space.iterations = 10
    space.gravity = CP.v(0, -1000)
    space.collision_slop = 2.0

    # Create segments around the edge of the screen.
    [{1, 1}, {1, -1}, {-1, -1}, {-1, 1}, {1, 1}].each_cons(2) do |(a, b)|
      shape = space.add CP::Segment.new(space.static_body,
        CP.v(340 * a[0], 260 * a[1]), CP.v(340 * b[0], 260 * b[1]), 20.0
      )
      shape.elasticity = 1
      shape.friction = 1
      shape.filter = NOGRAB_FILTER
    end

    200.times do
      body = space.add CP::Body.new
      body.position = CP.v(random.rand(-150.0..150.0), random.rand(-150.0..150.0))

      shape = space.add CP::Circle.new(body, radius: 10 + STICK_SENSOR_THICKNESS)
      shape.mass = 0.15
      shape.friction = 0.9
      shape.collision_type = COLLISION_TYPE_STICKY
    end

    space.add_collision_handler(COLLISION_TYPE_STICKY, StickyCollisionHandler.new)
  end

  class StickyCollisionHandler < CP::CollisionHandler
    def pre_solve(arb, space)
      # We want to fudge the collisions a bit to allow shapes to overlap more.
      # This simulates their squishy sticky surface, and more importantly
      # keeps them from separating and destroying the joint.

      # Track the deepest collision point and use that to determine if a rigid collision should occur.
      deepest = Float64::INFINITY

      # Grab the contact set and iterate over them.
      contacts = arb.contact_point_set
      contacts.points.each_index do |i|
        # Sink the contact points into the surface of each shape.
        pt = contacts.points[i]
        contacts.points[i] = CP::ContactPoint.new(
          pt.point_a - contacts.normal * STICK_SENSOR_THICKNESS,
          pt.point_b + contacts.normal * STICK_SENSOR_THICKNESS,
          pt.distance
        )
        deepest = {deepest, pt.distance}.min
      end

      # Set the new contact point data.
      arb.contact_point_set = contacts

      # If the shapes are overlapping enough, then create a
      # joint that sticks them together at the first contact point.
      if !arb.data && deepest <= 0
        body_a, body_b = arb.bodies

        # Create a joint at the contact point to hold the body in place.
        anchor_a = body_a.world_to_local(contacts.points[0].point_a)
        anchor_b = body_b.world_to_local(contacts.points[0].point_b)
        joint = CP::PivotJoint.new(body_a, body_b, anchor_a, anchor_b)

        # Give it a finite force for the stickyness.
        joint.max_force = 3000

        space.add joint

        # Store the joint on the arbiter so we can remove it later.
        arb.data = joint
      end

      # Position correction and velocity are handled separately so changing
      # the overlap distance alone won't prevent the collision from occuring.
      # Explicitly the collision for this frame if the shapes don't overlap using the new distance.
      deepest <= 0

      # Lots more that you could improve upon here as well:
      # * Modify the joint over time to make it plastic.
      # * Modify the joint in the post-step to make it conditionally plastic (like clay).
      # * Track a joint for the deepest contact point instead of the first.
      # * Track a joint for each contact point. (more complicated since you only get one data pointer).
    end

    def separate(arb, space)
      if (joint = arb.data.as(CP::PivotJoint?))
        # The joint won't be removed until the step is done.
        # Need to disable it so that it won't apply itself.
        # Setting the force to 0 will do just that
        joint.max_force = 0

        # Perform the removal in a post-step() callback.
        space.remove joint

        # NULL out the reference to the joint.
        # Not required, but it's a good practice.
        arb.data = nil
      end
    end
  end
end

require "../demo/run"
