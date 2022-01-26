function update_win()
 if btnp(❎) then
  transition_start()
 end
end

function draw_win()
 rectfill(0,60,128,82,0)
 print("you win!",46,62,7);
 print(points,46,69,7);
 print("press ❎ to restart",27,76,6);
end