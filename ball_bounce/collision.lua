
function circle_box(circle, box)
 --checks for a collision of the ball with a rectangle
 return not (
  -- below box
  circle.y - circle.r > box.y + box.h
  -- on top of box
  or circle.y + circle.r < box.y
  -- right of box
  or circle.x - circle.r > box.x + box.w
  -- left of box
  or circle.x + circle.r < box.x
 )
end

-- horizontal=true, vertical=false
function deflx_ball_box(ball,box)
 if ball.dx == 0 then
  return false
 elseif ball.dy == 0 then
  return true
 end

 -- quadrants
 -- q4 | q1
 -- -------
 -- q3 | q2
 local slope = ball.dy / ball.dx
 local cx,cy
 if slope > 0 and ball.dx > 0 then
  -- q1
  cx = box.x - ball.x
  cy = box.y - ball.y
  return cx > 0 and cy/cx < slope
 elseif slope < 0 and ball.dx > 0 then
  -- q2
  cx = box.x - ball.x
  cy = box.y + box.h - ball.y
  return cx > 0 and cy/cx >= slope
 elseif slope > 0 and ball.dx < 0 then
  -- q3
  cx = box.x + box.w - ball.x
  cy = box.y + box.h - ball.y
  return cx < 0 and cy/cx <= slope
 else -- slope < 0 and bdx < 0
  -- q4
  cx = box.x + box.w - ball.x
  cy = box.y - ball.y
  return cx < 0 and cy/cx >= slope
 end
end
