function update_gameover()
 if btnp(❎) then
  transition_start()
 end
end

function draw_gameover()
 rectfill(0,60,128,75,0)
 print("game over",46,62,7);
 print("press ❎ to restart",27,69,6);
end