-- harded bricks (needs to be hit more than once)
-- indestructible bricks
-- exploding bricks (destroys bricks around it (including hardened?))
-- power-ups
function draw_game()
	cls(1)
	circfill(ball.x, ball.y, ball.r, ball.c)
	rectfill(pad.x, pad.y, pad.x + pad.w - 1, pad.y + pad.h - 1, pad.c)

 draw_bricks(bricks)
 draw_pills(pills)
 draw_hud(lives, points, ball, pad)
end

function draw_hud(lives, points, ball, pad)
 rectfill(0,0,128,6,0)

 print("lives:" .. lives, 1, 1, 7)
 print("score:" .. points, 40, 1, 7)
 print("chain:" .. ball.chain, 100, 1, 7)
 print("debug: " .. debug, 1,10,7)

 if pad.sticky then
  rectfill(0, 88, 127, 96, 0)
  print("press ❎ to serve", 32, 90, 11)
  line(
   ball.x + ball.dx * 4, ball.y + ball.dy * 4,
   ball.x + ball.dx * 6, ball.y + ball.dy * 6,
   ball.c
  )
 end
end

function draw_bricks(bricks)
 local i
 for i=1,#bricks do
  if bricks[i].v then
    rectfill(
     bricks[i].x, bricks[i].y,
     -- '-1' due to w/h being
     -- inclusive when drawn to
     -- the screen
     bricks[i].x + bricks[i].w - 1,
     bricks[i].y + bricks[i].h - 1,
     bricks[i].col
    )
  end
 end
end

function update_game()
  frame = frame + 1
  slow = btn(4)
  if slow and not (frame % 10 == 0) then
    return
  end

	update_pad(pad, ball)

 if pad.sticky then
  ball.x = pad.x + flr(pad.w / 2)
  ball.y = pad.y - ball.r - 2
 else
  local next = {
   x = ball.x + ball.dx,
   y = ball.y + ball.dy
  }
  next = check_arena_collision(next, ball)
  check_ball_pad_collision(next, ball, pad)	
  check_ball_brick_collision(next, ball, bricks, levels)
  check_ball_pill_collision(ball, pills)
  update_pills(pills)
  ball.x = next.x
  ball.y = next.y
  
  check_game_state_transition(next.y,pad,ball)
 end
end

function check_ball_pill_collision(ball, pills)

end

function update_pad(pad, ball)
 local buttpress = false
	
	-- pad movement
	if btn(0) then
		pad.dx = -2.5
		buttpress = true
  if pad.sticky then
   ball.dx = -1
  end
	end
	
	if btn(1) then
		pad.dx = 2.5
		buttpress = true
  if pad.sticky then
   ball.dx = 1
  end
	end
	
 if pad.sticky and btnp(5) then
  pad.sticky = false
 end

	-- slow down pad
	if not(buttpress) then
		pad.dx = pad.dx / 1.17
	end

	pad.x += pad.dx
 pad.x = mid(0, pad.x, 128 - pad.w)
end

function check_arena_collision(next, ball)
	if next.x > (127 - ball.r) or next.x < ball.r then
		next.x = mid(ball.r,next.x,127 - ball.r)
		ball.dx = -ball.dx
		sfx(00)
	end

	if next.y < 9 then
		next.y = mid(9, next.y, 124)
		ball.dy = -ball.dy  
		sfx(00)
	end	
	
	return next
end

function check_ball_pad_collision(next, ball, pad)
 if not circle_box({x = next.x, y = next.y, r = ball.r}, pad) then
  return
 end

 local is_horizontal = deflx_ball_box(ball,pad)
 if is_horizontal then
  ball.dx =- ball.dx
  -- move ball outside of pad
  if ball.x < pad.x + pad.w / 2 then
   next.x = pad.x - ball.r
  else
   next.x = pad.x + pad.w + ball.r
  end
 else
  ball.dy =- ball.dy
  -- move ball outside of pad
  if ball.y > pad.y then
    -- bottom
   next.y = pad.y + pad.h + ball.r
  else 
    -- top
   next.y = pad.y - ball.r
   if abs(pad.dx)  > 2 then
    if sign(pad.dx) == sign(ball.dx) then
      set_angle(mid(0,2,ball.angle-1))
    elseif ball.angle == 2 then
     ball.dx = -ball.dx  
    else
      set_angle(mid(0,2,ball.angle+1))
    end 
  end
  end
 end

 points += 1
 ball.chain = 0
 sfx(01)
end

function check_ball_brick_collision(next, ball, bricks, levels)
 local circle = {x = next.x, y = next.y, r = ball.r}
 local hit_bricks = {}
 for i=1,#bricks do
  local brick = bricks[i]
  if brick.v and circle_box(circle, brick) then
   add(hit_bricks, brick)
  end
 end

 if #hit_bricks == 0 then
 elseif #hit_bricks == 1 then
  local brick = hit_bricks[1]
  brick_hit_actions[brick.type](ball, brick, next)
 else
  -- hit multiple bricks
  -- pick collision response where next position results in no collision

  -- calculate next frame for each collision

  local first_hit_brick = get_first_hit_brick(ball, hit_bricks)
  brick_hit_actions[first_hit_brick.type](ball, first_hit_brick)
 end

 if is_level_finished(bricks) then
  _draw() -- extra draw to clear the last brick
  if level_num == #levels then
   transition_win()
  else
   transition_stageclear()
  end
 end
end

function get_first_hit_brick(ball, hit_bricks)
 --debug = 0
 local still_hit_bricks = {}
 -- try up to 50 times to resolve collision
 for i=20,1,-1 do
  if #still_hit_bricks == 0 then
   debug = ball.dx .. ',' .. (ball.dx / i)
   local next = {x = ball.x + (ball.dx / i), y = ball.y + (ball.dy / i), r = ball.r}
   for j=1,#hit_bricks do
    local brick = hit_bricks[j]
    if circle_box(next, brick) then
     add(still_hit_bricks, brick)
    end
   end
  else
   debug = debug .. ' ' .. i
   break
  end
 end
 for i=1,#still_hit_bricks do
  still_hit_bricks[i].col = (still_hit_bricks[i].col + 1 % 7) + 4
 end
 
 return still_hit_bricks[1]
end

function check_game_state_transition(nexty,pad,ball)
 if nexty > 127 then
  sfx(2)
  lives -= 1
  if lives < 0 then
   transition_gameover()
  else
   serve_ball(pad)
  end
 end
end

function start_game()
 debug = ''
 frame = 0
 lives=3
 points=0
 reset_pills()

 -- 'x' - empty
 -- 'b' - normal
 -- 'h' - hardened
 -- 'i' - indestructible
 -- 's' - exploding
 -- 'p' - powerup
 -- '1' - '9' - repeat last brick n times
 levels = {}
 levels[1] =
  "hiiiiiiiiii" ..
  "ixxxxxxxxxi" ..
  "ixxxxxxxxxx" ..
  "iiiiiiiiixx"
 --levels[1] = "///b9b/x4px4"
 levels[2] =
  "///xxbbbbbbb/" ..
  "xxbbbbbbb/" ..
  "xxbbbbbbb/" ..
  "xxbbbbbbb/"
 levels[3] =
  "xxsxxbxxsxx" ..
  "xxsxxbxxsxx" ..
  "xxsxxbxxsxx" ..
  "xxsxxbxxsxx" ..
  "xxsxxbxxsxx" ..
  "xxixxbxxixx"
 level_num = 0
 next_level()
end

brick_type_normal = 1
brick_type_harded = 2
brick_type_indestructible = 3
brick_type_exploding = 4
brick_type_powerup = 5

function get_brick_type(c)
 if c == 'b' then return brick_type_normal
 elseif c == 'h' then return brick_type_harded
 elseif c == 'i' then return brick_type_indestructible
 elseif c == 's' then return brick_type_exploding
 elseif c == 'p' then return brick_type_powerup
 end
end

pill_type_slow = 1
pill_sprs = {1}
pill_hit_actions = {function()end}

brick_colors = {14,4,5,9,12}
brick_break_hits = {1,2,-1,1,1}
brick_hit_actions = {
 function (ball, normal_brick)
  bounce(ball, normal_brick)
  points += 10 * ball.chain
  normal_brick.v = false
  sfx(3 + ball.chain)
  ball.chain = mid(0,7,ball.chain + 1)
 end,

 function (ball, hardened_brick)
  bounce(ball, hardened_brick)
  points += 10 * ball.chain
  hardened_brick.break_hits -= 1
  if hardened_brick.break_hits == 0 then
   hardened_brick.v = false
  elseif hardened_brick.break_hits == 1 then
   hardened_brick.col = 15
  end
  sfx(3 + ball.chain)
  ball.chain = mid(1,7,ball.chain + 1)
 end,

 function (ball, indestructible_brick)
  bounce(ball, indestructible_brick)
  sfx(10)
 end,

 function (ball, exploding_brick)
  bounce(ball, exploding_brick)
  points += 10 * ball.chain
  exploding_brick.v = false
  sfx(3 + ball.chain)
  ball.chain = mid(0,7,ball.chain + 1)
 end,

 function (ball, powerup_brick)
  bounce(ball, powerup_brick)
  add_pill(pills, powerup_brick.x, powerup_brick.y, pill_type_slow)
  points += 10 * ball.chain
  powerup_brick.v = false
  sfx(3 + ball.chain)
  ball.chain = mid(0,7,ball.chain + 1)
 end
}

function bounce(ball, brick)
 if deflx_ball_box(ball, brick) then
  -- horizontal bounce
  ball.dx =- ball.dx
 else
  -- vertical bounce
  ball.dy =- ball.dy
 end
end

function next_level()
 level_num += 1
 pad={x=52,y=120,dx=0,w=25,h=4,c=7,sticky=false}
 bricks = {}
 level = levels[level_num]
 build_bricks(level, bricks)
 
 serve_ball(pad)
end

function build_bricks(level, bricks)
 local bricks_per_line = 11

 local previous
 local brick_num = 0
 for str_idx=1,#level do
  brick_num = brick_num + 1

  local c = sub(level, str_idx, str_idx)
  if c == 'x' then
   -- empty
  elseif '1' <= c and c <= '9' then
   if not (previous == 'x') then
    local brick_type = get_brick_type(previous)
    add_bricks(bricks, brick_num, brick_type, c+0, bricks_per_line)
   end
   brick_num += (c-1)
  elseif c == '/' then
   local row = get_row(brick_num, bricks_per_line)
   brick_num = (row + 1) * bricks_per_line
  else
   local brick_type = get_brick_type(c)
   add_brick(bricks, brick_num, brick_type, bricks_per_line)
  end
  previous = c
 end
end

function add_bricks(bricks, brick_num, type, count, bricks_per_line)
 for i=1,count do
  add_brick(bricks, brick_num + (i - 1), type, bricks_per_line)
 end
end

function get_row(brick_num, bricks_per_line)
 return flr((brick_num - 1) / bricks_per_line)
end

function add_brick(bricks, brick_num, type, bricks_per_line)
 local brick_width = 10
 local brick_height = 7
 local row = get_row(brick_num, bricks_per_line)

 local top_padding = 20
 local left_padding = 4
 local py = top_padding + row * (brick_height + 1)
 local px = left_padding + ((brick_num - 1) % bricks_per_line) * (brick_width + 1)

 add(
  bricks,
  {
    x = px,
    y = py,
    v = true,
    w = brick_width,
    h = brick_height,
    type = type,
    col = brick_colors[type],
    break_hits = brick_break_hits[type]
  }
 )
end

function add_pill(pills,px,py,type)
 add(pills, {x=px,y=py,v=true,type=type,dy=0.25,dx=0,spr=pill_sprs[type]})
end

function draw_pills(pills)
 local pill
 for i=1,#pills do
  pill = pills[i]
  if pill.v then
   spr(pill.spr,pill.x,pill.y)
  end
 end
end

function update_pills(pills)
 local pill
 for i=1,#pills do
  pill = pills[i]
  if pill.v then
   pill.y += pill.dy
   pill.x += pill.dx
   if pill.y > 128 then
    pill.v = false
   end
  end
 end
end

function reset_pills()
 pills = {}
end

function serve_ball(pad)
 pad.sticky = true
 ball = {
  x = pad.x + flr(pad.w / 2),
  y = pad.y - 2 - 2,
  dx = 1,
  dy = -1,
  c = 10,
  r = 2,
  angle = 1,
  chain = 0
 }
 reset_pills()
end

function sign(n)
 if n < 0 then return -1
 elseif n > 0 then return 1
 else return 0 end
end

function set_angle(angle)
  ball.angle = angle
  if angle == 2 then
    ball.dx = 0.5 * sign(ball.dx)
    ball.dy = 1.3 * sign(ball.dy)
  elseif angle == 0 then
    ball.dx = 1.3 * sign(ball.dx)
    ball.dy = 0.5 * sign(ball.dy)
  else
    ball.dx = 1 * sign(ball.dx)
    ball.dy = 1 * sign(ball.dy)
  end
end

function is_level_finished(bricks)
 local brick
 for i=1,#bricks do
  brick = bricks[i]
  if not (brick.type == brick_type_indestructible) and brick.v then
   return false
  end
 end
 return true
end