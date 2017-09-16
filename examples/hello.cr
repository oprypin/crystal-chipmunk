require "chipmunk"

gravity = CP.v(0, -100)

space = CP::Space.new
space.gravity = gravity

ground = CP::Segment.new(space.static_body, CP.v(-20, 5), CP.v(20, -5), 0.0)
ground.friction = 1.0
space.add(ground)

radius = 5.0
mass = 1.0

moment = CP::Circle.moment(mass, 0.0, radius)

ball_body = space.add(CP::Body.new(mass, moment))
ball_body.position = CP.v(0, 15)

ball_shape = space.add(CP::Circle.new(ball_body, radius))
ball_shape.friction = 0.7

time_step = 1.0/60.0
time = 0.0

while time < 2
  pos = ball_body.position
  vel = ball_body.velocity
  printf(
    "Time is %5.2f. ball_body is at (%5.2f, %5.2f). Its velocity is (%5.2f, %5.2f)\n",
    time, pos.x, pos.y, vel.x, vel.y
  )

  space.step(time_step)
  time += time_step
end

