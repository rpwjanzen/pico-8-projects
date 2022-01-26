function update_stageclear()
 if btnp(❎) then
  transition_next_level()
 end
end

function draw_stageclear()
 rectfill(0,60,128,75,0)
 print("stage clear!",46,62,7);
 print("press ❎ to continue",27,69,6);
end