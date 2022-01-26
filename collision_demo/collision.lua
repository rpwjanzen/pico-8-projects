-- collision response
-- need
--  collision normal
--   direction impulse will be applied
--  penetration depth
--   used to solve for the impulse magnitude

-- collision type (aka. manifold)
-- collision = {
-- a = a,
-- b = b,
-- p = f, -- depth of collision
-- n = {x=x,y=y} -- direction to resolve collision, normal
-- }

-- collision (manifold) generation
function collision_manifold(a, b)
 local m
 if a.type == BODY_TYPE_CIRCLE and b.type == BODY_TYPE_CIRCLE then
  m = {a = a, b = b, normal = {x = 0, y = 0}, p = 0}
  circle_circle_collision(m)
 elseif a.type == BODY_TYPE_CIRCLE and b.type == BODY_TYPE_BOX then
  m = {a = b, b = a, normal = {x = 0, y = 0}, p = 0}
  box_circle_collision(m)
 elseif a.type == BODY_TYPE_BOX and b.type == BODY_TYPE_CIRCLE then
  m = {a = a, b = b, normal = {x = 0, y = 0}, p = 0}
  box_circle_collision(m)
 elseif a.type == BODY_TYPE_BOX and b.type == BODY_TYPE_BOX then
  m = {a = a, b = b, normal = {x = 0, y = 0}, p = 0}
  box_box_collision(m)
 end
 --debug = debug .. "\nm.n: " .. m.normal.x .. "," .. m.normal.y .. " p: " .. m.penetration
 return m
end

-- find closest point on box to circle, then do circle-circle collision
-- penetration depth is difference between closest poin to circle and circle radius
-- ticky case: if circle inside box, need to clip circle center to closest edge of box and flip normal
function box_circle_collision(m)
  m.penetration = 0
  m.normal = {x = 0, y = 0}

  local box = m.a
  local circle = m.b
  local diff = vec_diff(circle.position, box.position)

  -- closest point on box edge to center of circle
  local closest_point_on_box_edge =
    vec_mid(
    vec_diff(circle.position, box.position), -- is in "box" space
    {x = -box.hw, y = -box.hh},
    {x = box.hw, y = box.hh}
  )
  debug = ''
  --debug = "diff: " .. diff.x .. "," .. diff.y

  --debug = debug .. "\nedge: " .. closest_point_on_box_edge.x .. "," .. closest_point_on_box_edge.y
  -- debug = debug .. '\nrng: [' .. box.position.x - box.hw .. '..' .. box.position.x + box.hw .. '],'
  -- debug = debug .. '[' .. box.position.y - box.hh .. '..' .. box.position.y + box.hh .. ']'

  -- true, if circle center is within box bounds; otherwise, false
  local is_inside = vec_eq(diff,closest_point_on_box_edge)

  -- circle center is inside the box, need to clamp the circle's center to the closest edge
  if (is_inside) then
    --debug = debug .. '\ninside'
    -- find closest axis
    if (abs(diff.x) > abs(diff.y)) then
      if (closest_point_on_box_edge.x > 0) then
        closest_point_on_box_edge.x = box.hw
      else
        closest_point_on_box_edge.x = -box.hw
      end
    else -- y-axis is shorter
      if (closest_point_on_box_edge.y > 0) then
        closest_point_on_box_edge.y = box.hh
      else
        closest_point_on_box_edge.y = -box.hh
      end
    end
  else
    --debug = debug .. '\noutside'
  end

  -- direction to move circle to decrease intersection
  local move_circle_dir = vec_diff(diff, closest_point_on_box_edge)
  local dSquared = vec_length_squared(move_circle_dir)
  --debug = debug .. "\nd^2: " .. dSquared
  if (dSquared > (circle.radius * circle.radius) and not is_inside) then
    -- circle radius is shorter than distance to closest point and
    -- circle is not inside the box
    --debug = debug .. "\napart"
    return false
  else
    --debug = debug .. "\ncollision"
  end

  local d = sqrt(dSquared)
  local normal = vec_div(move_circle_dir, d)
  if (is_inside) then
    m.normal = vec_negate(normal)
  else
    m.normal = normal
  end
  m.penetration = circle.radius - d
  return true
end

-- collision vector will be along b - a vector
-- true, if there is a collision; otherwise, false
function circle_circle_collision(m)
 local a = m.a
 local b = m.b
 local diff = vec_diff(b.position, a.position)
 local r = a.radius + b.radius
 r = r * r

 -- no collision
 if vec_length_squared(diff) > r then
  return false
 end

 -- distance penetrating along collision vector
 local d = vec_length(diff)
 if (not d == 0) then
  m.penetration = r - d
  m.normal = vec_div(diff, d)
  return true
 else -- distance is 0. items are on same spot
  -- arbitrary, but consistent
  m.penetration = a.radius
  m.normal = vec_right
  return true
 end
end

-- collision normal will be along one of the boxes faces normals
-- (perpendicular to a face)
function box_box_collision(m)
 local a = m.a
 local b = m.b
 local diff = vec_diff(b.position, a.position)

 local a_extent = a.hw
 local b_extent = b.hw
 local x_overlap = a_extent + b_extent - abs(diff.x)

 -- SAT on x axis
 if (x_overlap > 0) then
  -- overlap on y-axis
  a_extent = a.hh
  b_extent = b.hh
  local y_overlap = a_extent + b_extent - abs(diff.y)
  if (y_overlap > 0) then
   -- determine which axis penetrates least
   if (x_overlap > y_overlap) then
    if (diff.x < 0) then
     m.normal = vec_left
    else
     m.normal = vec_right
    end
    m.penetration = x_overlap
    return true
   else -- x_overlap <= y_overlap
    if (diff.y < 0) then
     m.normal = vec_up
    else
     m.normal = vec_down
    end
    m.penetration = y_overlap
    return true
   end
  end
 end

 return false
end

-- rigid physics objects
-- pos = position in x,y
-- velocity = velocity in dx,dy
-- mass = mass, use 0 for infinite
-- inv_mass = inverse of mass (1/m), useful for resolving collision, use 0 for infinite
-- restitution - bounciness 0 = no bounce, 1 = 100% bounce
function resolve_collision(m)
 local a = m.a
 local b = m.b
 if a.inv_mass == 0 and b.inv_mass == 0 then
  -- items are both infinite mass and immovable
  return
 end

 local relative_velocity = vec_diff(b.velocity, a.velocity)
 local relative_velocity_along_collision = vec_dot(relative_velocity, m.normal)
 --debug = debug .. "\nrv along n: " .. relative_velocity_along_collision
 local are_separating = relative_velocity_along_collision > 0 
 if (are_separating) then
  return -- objects are separating
 end

 if not(a.inv_mass == 0) then
   local j = -(1 + a.restitution) * relative_velocity_along_collision
   j = j / a.inv_mass

   -- apply impulse
   local impulse = vec_mul(m.normal, j)
   local a_impulse = vec_mul(impulse, a.inv_mass)
   a.velocity = vec_sub(a.velocity, a_impulse)
 end

 if not(b.inv_mass == 0) then
   local j = -(1 + b.restitution) * relative_velocity_along_collision
   j = j / b.inv_mass

   -- apply impulse
   local impulse = vec_mul(m.normal, j)
   local b_impulse = vec_mul(impulse, b.inv_mass)
   b.velocity = vec_add(b.velocity, b_impulse)
 end
 -- apply positional correction?
 --positional_correction(m)
end

-- used to resolve accumulated math errors so that
-- "stationary" items do not "sink" into each other
-- a = obj A, b = obj B, n = normal vector of collision
function positional_correction(m)
  local a = m.a
  local b = m.b
  if (a.inv_mass == 0 and b.inv_mass == 0) then
   -- both items have infinite mass and are immovable
   return
  end

  local percent = 0.2 -- 20% - 80%: percent to scale penetrationd depth
  local slop = 0.1 -- 0.01 - 0.1: below which we do not perform correction
  local correction = vec_mul(m.normal, max(m.penetration - slop, 0) / (a.inv_mass + b.inv_mass) * percent)
  a.position = vec_diff(a.position, vec_mul(correction, a.inv_mass))
  b.position = vec_add(b.position, vec_mul(correction, b.inv_mass))
end

function is_box_box_collided(a, b)
 -- a left of b
 if (a.position.x + a.hw < b.position.x - b.hw) then
  -- a right of b
  return false
 elseif (a.position.x - a.hw > b.position.x + b.hw) then
  -- a above b
  return false
 elseif (a.position.y + a.hh < b.position.y - b.hh) then
  -- a below b
  return false
 elseif (a.position.y - a.hh > b.position.y + b.hh) then
  return false
 end

 return true
end

function is_circle_circle_collided(a, b)
 local r = a.radius + b.radius
 r = r * r
 -- radius squared < x & y squared. a^2 = b^2 + c^2
 return r <
  (a.position.x + b.position.x) * (a.position.x + b.position.x) +
   (a.position.y + b.position.y) * (a.position.y + b.position.y)
end

function is_box_circle_collided(box, circle)
 return is_circle_box_collided(circle, box)
end

function is_circle_box_collided(circle, box)
 local c_pos = circle.position
 local c_r = circle.radius
 -- checks for a collision of the ball with a rectangle
 return not (
   -- below box  
   c_pos.y - c_r > box.position.y + box.hh or
   -- on top of box
   c_pos.y + c_r < box.position.y - box.hh or
   -- right of box
   c_pos.x - c_r > box.position.x + box.hw or
   -- left of box
   c_pos.x + c_r < box.position.x - box.hw
  )
end
