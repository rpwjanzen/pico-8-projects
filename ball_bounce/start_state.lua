function draw_start()
 cls(2)
 print("pico hero breakout",30,30,7)
 print("press ❎ to start",32,80,11)
end

function update_start()
 if btnp(❎) then
  transition_game()
 end
end