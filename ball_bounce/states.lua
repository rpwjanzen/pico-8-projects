function transition_start()
 transition_state(update_start, draw_start)
end

function transition_gameover()
 transition_state(update_gameover, draw_gameover)
end

function transition_game()
 start_game()
 transition_state(update_game, draw_game)
end

function transition_next_level()
 next_level()
 transition_state(update_game, draw_game)
end

function transition_stageclear()
 transition_state(update_stageclear, draw_stageclear)
end

function transition_win()
 transition_state(update_win, draw_win)
end

function transition_state(update,draw)
 _draw = draw
 _update60 = update
end