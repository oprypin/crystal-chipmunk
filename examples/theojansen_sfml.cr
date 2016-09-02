require "chipmunk"
require "crsfml"
require "chipmunk/chipmunk_crsfml.cr"


window = SF::RenderWindow.new(
  SF::VideoMode.new(960, 720), "Theo Jansen Machine",
  settings: SF::ContextSettings.new(depth: 24, antialiasing: 8)
)
window.framerate_limit = 180

debug_draw = SFMLDebugDraw.new(window, SF::RenderStates.new(
  SF::Transform.new.translate(window.size / 2).scale(1, -1).scale(1.5, 1.5)
))

space = CP::Space.new
space.iterations = 20
space.gravity = CP.v(0, -500)

static_body = space.static_body

# Create segments around the edge of the screen.
[{1, 1}, {1, -1}, {-1, -1}, {-1, 1}].each_cons(2) do |(a, b)|
  shape = space.add CP::SegmentShape.new(static_body, CP.v(320 * a[0], 240 * a[1]), CP.v(320 * b[0], 240 * b[1]), 0.0)
  shape.elasticity = 1
  shape.friction = 1
end

offset = 30.0
seg_radius = 3.0

# make chassis
chassis_mass = 2.0
a = CP.v(-offset, 0.0)
b = CP.v(offset, 0.0)
chassis = space.add CP::Body.new(chassis_mass, CP.moment_for_segment(chassis_mass, a, b, 0.0))

shape = space.add CP::SegmentShape.new(chassis, a, b, seg_radius)
shape.filter = CP::ShapeFilter.new(1, CP::ALL_CATEGORIES, CP::ALL_CATEGORIES)

# make crank
crank_mass = 1.0
crank_radius = 13.0
crank = space.add CP::Body.new(crank_mass, CP.moment_for_circle(crank_mass, crank_radius, 0.0, CP.v(0, 0)))

shape = space.add CP::CircleShape.new(crank, crank_radius, CP.v(0, 0))
shape.filter = CP::ShapeFilter.new(1, CP::ALL_CATEGORIES, CP::ALL_CATEGORIES)

space.add CP::PivotJoint.new(chassis, crank, CP.v(0, 0), CP.v(0, 0))

side = 30.0

4.times do |i|
  anchor = CP::Vect.angle(Math::PI * i / 2) * crank_radius

  leg_mass = 1.0

  # make leg
  a = CP.v(0, 0)
  b = CP.v(0, side)
  upper_leg = space.add CP::Body.new(leg_mass, CP.moment_for_segment(leg_mass, a, b, 1.0))
  upper_leg.position = CP.v(offset, 0.0)

  shape = space.add CP::SegmentShape.new(upper_leg, a, b, seg_radius)
  shape.filter = CP::ShapeFilter.new(1, CP::ALL_CATEGORIES, CP::ALL_CATEGORIES)

  space.add CP::PivotJoint.new(chassis, upper_leg, CP.v(offset, 0.0), CP.v(0, 0))

  # lower leg
  a = CP.v(0, 0)
  b = CP.v(0, -1*side)
  lower_leg = space.add CP::Body.new(leg_mass, CP.moment_for_segment(leg_mass, a, b, 0.0))
  lower_leg.position = CP.v(offset, -side)

  shape = space.add CP::SegmentShape.new(lower_leg, a, b, seg_radius)
  shape.filter = CP::ShapeFilter.new(1, CP::ALL_CATEGORIES, CP::ALL_CATEGORIES)

  shape = space.add CP::CircleShape.new(lower_leg, seg_radius*2.0, b)
  shape.filter = CP::ShapeFilter.new(1, CP::ALL_CATEGORIES, CP::ALL_CATEGORIES)
  shape.elasticity = 0.0
  shape.friction = 1.0

  space.add CP::PinJoint.new(chassis, lower_leg, CP.v(offset, 0.0), CP.v(0, 0))

  space.add CP::GearJoint.new(upper_leg, lower_leg, 0.0, 1.0)

  diag = Math.hypot(side, offset)

  constraint = space.add CP::PinJoint.new(crank, upper_leg, anchor, CP.v(0.0, side))
  constraint.dist = diag

  constraint = space.add CP::PinJoint.new(crank, lower_leg, anchor, CP.v(0, 0))
  constraint.dist = diag

  offset *= -1
end


motor = space.add CP::SimpleMotor.new(chassis, crank, 6.0)



while window.open?
  while event = window.poll_event
    if event.is_a? SF::Event::Closed
      window.close()
    end
  end

  y = (SF::Keyboard.key_pressed?(SF::Keyboard::Up) ? 1 : 0) - (SF::Keyboard.key_pressed?(SF::Keyboard::Down) ? 1 : 0)
  x = (SF::Keyboard.key_pressed?(SF::Keyboard::Right) ? 1 : 0) - (SF::Keyboard.key_pressed?(SF::Keyboard::Left) ? 1 : 0)
  coef = (2.0 + y)/3.0
  rate = x * 10.0 * coef
  motor.rate = rate
  motor.max_force = (rate != 0.0 ? 100000 : 0)
  space.step(1/180.0)

  window.clear(SF.color(52, 62, 72))
  debug_draw.draw space
  window.display()
end
