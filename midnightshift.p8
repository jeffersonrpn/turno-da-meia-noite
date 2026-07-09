pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- init e update
function _init()
  t = 0
  total_time = 0
  p_ani = {16,17}
  goals_ani = {35,36,37,38,39}
  ghost_ani = {32,33}
  x_ani={59,60}
  o_ani={45,61}
  
  dirx={-1,1,0,0}
  diry={0,0,-1,1}
  
  reset_run()
  menu_init()
  
  music_playing = false
end
 
function _update()
  t += 1
  if _drw == draw_game then
    level_timer -= 1
    update_ghosts()
    update_freeze()
		  if level_timer <= 0 then
      level_timer = 0
		    on_time_over()
		    return
		  end
  end
  _upd()
end
 
function _draw()
 _drw()
end
 
function start_game()
  p_t = 0
  p_x = levels[current_level].p_x
  p_y = levels[current_level].p_y
  p_ox = 0
  p_oy = 0
  p_sox = 0
  p_soy = 0
  p_flip = false
	p_frozen = false
 
  p_mov = nil
  
  p_next_dx = 0
  p_next_dy = 0
 
  tombs = {} 
  ghosts = {}
  ghost_spawn_timer = 0
	ghost_spawn_interval = 240
	freeze_timer = 0
 
  -- tempo
  level_time = levels[current_level].time * 60 -- converte segundos em frames
  level_timer = level_time
end
-->8
-- game

levels = {
  {
    map_x = 0,
    map_y = 0,
    p_x = 8,
    p_y = 11,
    time = 10,
    ghosts = 3,
    ghosts_int = 160,
    tombs = {
      {7,9,18, 5},
      {7,8,19, 6},
      {8,8,20, 7}
    }
  },
  {
    map_x = 16,
    map_y = 0,
    p_x = 8,
    p_y = 12,
    time = 20,
    ghosts = 6,
    ghosts_int = 160,
    tombs = {
      {7,10,18, 5},
      {10,13,19, 6},
      {8,5,20, 7}
    }
  },
  {
    map_x = 32,
    map_y = 0,
    p_x = 8,
    p_y = 7,
    time = 30,
    ghosts = 6,
    ghosts_int = 160,
    tombs = {
      {10,12,18, 5},
      {2,7,19, 6},
      {6,5,20, 7}
    }
  },
  {
    map_x = 48,
    map_y = 0,
    p_x = 8,
    p_y = 2,
    time = 30,
    ghosts = 3,
    ghosts_int = 80,
    tombs = {
      {10,9,18, 5},
      {3,7,19, 6},
      {12,4,20, 7}
    }
  },
  {
    map_x = 64,
    map_y = 0,
    p_x = 7,
    p_y = 10,
    time = 30,
    ghosts = 6,
    ghosts_int = 80,
    tombs = {
      {13,12,18, 5},
      {2,12,19, 6},
      {13,4,20, 7}
    }
  }
}

function game_init()
  start_game()
  
  -- toca musica apenas se ainda nao estiver tocando
  if not music_playing then
    music(22)
    music_playing = true
  end
 
  for t in all(levels[current_level].tombs) do
    add_tomb(t[1], t[2], t[3], t[4])
  end
  set_state(update_game, draw_game)
end

function update_game()
  handle_player_input()
  
  -- se houver um movimento buffered, inicie-o
  if p_next_dx ~= 0 or p_next_dy ~= 0 then
    local next_dx, next_dy = p_next_dx, p_next_dy
    p_next_dx = 0 -- limpa o buffer
    p_next_dy = 0
    
    move_player(next_dx, next_dy)
  end
end

function update_pturn()
  handle_player_input() 
  
  p_t = min(p_t+0.125, 1)
  p_mov()
  tomb_mov()
  
  -- fim do movimento
  if p_t == 1 then
    local prev_upd = _upd
    check_goals()
    
    -- se o nivel/jogo nao terminou em check_goals
    if _upd == prev_upd then
      
      -- tenta iniciar o proximo
      -- movimento encadeado (buffered)
      if p_next_dx ~= 0 or p_next_dy ~= 0 then
        local next_dx, next_dy = p_next_dx, p_next_dy
        p_next_dx = 0 -- limpa o buffer
        p_next_dy = 0
        
        -- inicia proxima animacao
        -- (start_walk/start_bump)
        move_player(next_dx, next_dy)
      else
        -- se nao ha movimento
        -- retorna ao estado idle
        _upd = update_game
      end
    end
  end
end

function handle_player_input()
  if p_frozen then return end
  
  for i=0,3 do
    if btnp(i) then
      -- armazena o proximo movimento desejado
      p_next_dx = dirx[i+1]
      p_next_dy = diry[i+1]
      return
    end
  end
end

function update_ghosts()
  ghost_spawn_timer += 1
  local int = levels[current_level].ghosts_int
  if ghost_spawn_timer > int then
    ghost_spawn_timer = 0
    spawn_ghosts_batch()
  end

  for g in all(ghosts) do
    g.x += g.dx
    g.y += g.dy

    -- remove se saiu da tela
    if g.x < -8 or g.x > 128 or g.y < -8 or g.y > 128 then
      del(ghosts, g)
    end

    -- colisao com jogador
    if abs(g.x - p_x * 8) < 6 and abs(g.y - p_y * 8) < 6 then
      freeze_player()
      del(ghosts, g)
    end
  end
end

function update_freeze()
  if p_frozen then
    p_ani={16}
    freeze_timer -= 1
    if freeze_timer <= 0 then
      p_frozen = false
      p_ani={16,17}
    end
  end
end

function mov_walk()
  p_ox = p_sox * (1-p_t)
  p_oy = p_soy * (1-p_t)
end

function mov_bump()
  local mov_time = p_t
  if p_t > 0.5 then
    mov_time = 1 - p_t
  end
  p_ox = p_sox * mov_time
  p_oy = p_soy * mov_time
end

function tomb_mov()
  for tomb in all(tombs) do
	  if tomb.t < 1 then
	    tomb.t = min(tomb.t + 0.125, 1)
	    tomb.ox *= (1 - tomb.t)
	    tomb.oy *= (1 - tomb.t)
	  end
	 end
end
 
function draw_game()
  local lvl = levels[current_level]
  cls(0)
  map(lvl.map_x, lvl.map_y, 0, 0, 16, 16)
  -- lapides
  for tomb in all(tombs) do
    spr(tomb.s, tomb.x * 8 + tomb.ox, tomb.y * 8 + tomb.oy)
  end
  -- jogador
  local shake_x = 0
  if p_frozen then
    if t % 8 == 1 then
      shake_x = 1
    else
      shake_x = -1
    end
    if t % 8 < 4 then
      pal(1, 3) 
      pal(2, 14)
    end
  end
  draw_spr(get_frame(p_ani, 8, 0), p_x * 8 + p_ox + shake_x, p_y * 8 + p_oy, p_flip)
  pal()
  -- fantasmas
  for g in all(ghosts) do
    draw_spr(get_frame(ghost_ani, 8, 0), g.x, g.y)
  end
  -- hud
  draw_hud()
end
-->8
-- auxiliares

function get_frame(ani, _t, pause)
  local n = #ani
  local duration = n * _t
  local cycle = duration + pause
  
  local cycle_time = t % cycle
  
  if cycle_time < duration then
    -- normal animation
    local i = flr(cycle_time / _t) + 1
    return ani[i]
  else
    -- pause on first frame
    return ani[1]
  end
end

function draw_spr(_spr,_x,_y, _flip)
  spr(_spr, _x, _y, 1, 1, _flip)
end

function set_state(upd, drw)
  _upd = upd
  _drw = drw
end

function add_tomb(x, y, _spr, _fig)
  add(tombs, {
    x = x,
    y = y,
    ox = 0,
    oy = 0,
    t = 1,
    s = _spr,
    fig = _fig,
    done = false
  })
end

function tomb_at(x, y)
  for t in all(tombs) do
    if t.x == x and t.y == y then
      return t
    end
  end
  return nil
end

function spawn_ghosts_batch()
  -- numero simultaneo permitido pela fase
  local maxg = levels[current_level].ghosts
  -- quantidade aleatoria de fantasmas
  local n = flr(rnd(maxg)) + 1
  -- todos os possiveis pontos de spawn
  local points = {}
  -- fantasmas surgem nas margens
  -- limites Y 3..14 e X 3..14
  for i=3,14 do
    add(points, {x=-8, y=i*8, dx=1, dy=0})
    add(points, {x=128, y=i*8, dx=-1, dy=0})
    add(points, {x=i*8, y=-8, dx=0, dy=1})
    add(points, {x=i*8, y=128, dx=0, dy=-1})
  end
  -- embaralhar a lista para picks aleatorios
  -- (Fisher-Yates simplificado)
  for i=#points,2,-1 do
    local j = flr(rnd(i)) + 1
    points[i], points[j] = points[j], points[i]
  end

  -- spawnar fantasmas sem repetir posicoes
  for i=1,min(n, #points) do
    local p = points[i]
    add(ghosts, {
      x = p.x,
      y = p.y,
      dx = p.dx,
      dy = p.dy
    })
  end
end

function tile_at(x, y)
  local lvl = levels[current_level]
  return mget(lvl.map_x + x, lvl.map_y + y)
end

function print_r(text, x, y, c)
		local width = #text * 4
		local xo = x - width
		print(text, xo, y, c)
end

function print_center(text, y, c)
 	local width = #text * 4
 	local x = (128 - width) / 2
 	print(text, x, y, c)
end

function draw_frame(x,y,w,h,c,s)
  local xt,yt,wt,ht=x*8,y*8,w*8,h*8
  local x2,y2=xt+wt,yt+ht
  rectfill(xt,yt,x2,y2,c)
  rect(xt-1,yt-1,x2+1,y2+1,5)
  rect(xt,yt,x2,y2,7)
  rect(xt+1,yt+1,x2-1,y2-1,5)

  -- caveiras
  spr(s,xt-4,yt-4)
  spr(s,x2-3,yt-4,1,1,true)
  spr(s,xt-4,y2-3)
  spr(s,x2-3,y2-3,1,1,true)
end

function draw_text(text, x, y, w, c)
  local maxw = w*8 - 7
  local lines = wrap(text, maxw)

  local px = x*8 + 5
  local py = y*8 + 5

  for line in all(lines) do
    print(line, px, py, c)
    py += 6
  end
end

function wrap(text, maxw)
  local lines = {}
  local line = ""
  for word in all(split(text," ")) do
    local test = (line=="" and word) or (line.." "..word)
    if print(test,0,-8) > maxw then
      add(lines, line)
      line = word
    else
      line = test
    end
  end
  add(lines, line)
  return lines
end
-->8
-- gameplay

function move_player(dx, dy)
  local dest_x, dest_y = p_x+dx, p_y+dy
	 local tile = tile_at(dest_x, dest_y)
	 
  if dx < 0 then
    p_flip = true
  elseif dx > 0 then
    p_flip = false
  end
  
  -- colisao com parede
	 if fget(tile, 0) then
	   start_bump(dx, dy)
		  return
		end
		
		-- colisao com lapide
		local tomb = tomb_at(dest_x, dest_y)

  if tomb then
		  local push_x, push_y = dest_x+dx, dest_y+dy
		  
		  -- se ha parede ou outra
		  -- lapide, bump
		  if fget(tile_at(push_x, push_y),0) or tomb_at(push_x, push_y) then
		    start_bump(dx, dy)
		    return
		  end
		  
		  -- inicia animacao da lapide
		  tomb.x += dx
		  tomb.y += dy
		  tomb.ox = -dx*8
		  tomb.oy = -dy*8
		  tomb.t = 0
		end
	 
  p_x += dx
  p_y += dy
 
  start_walk(dx, dy)
end

function start_bump(dx, dy)
  p_sox,p_soy = dx*4,dy*4
  p_ox,p_oy = 0,0
  p_t = 0
  _upd  = update_pturn
  p_mov = mov_bump
end

function start_walk(dx, dy)
  p_sox,p_soy = -dx*8,-dy*8
  p_ox,p_oy = p_sox,p_soy
  p_t = 0
  _upd  = update_pturn
  p_mov = mov_walk
end

function spawn_ghost()
  local lvl = levels[current_level]
  if #ghosts >= lvl.ghosts then
    return
  end

  local dir = rnd(4)
  local x, y, dx, dy

  -- esquerda -> direita
  if dir == 0 then
    x = 2
    y = flr(rnd(13) + 3)
    dx, dy = 1, 0
  -- direita -> esquerda
  elseif dir == -1 then
    x = 16
    y = flr(rnd(13) + 3)
    dx, dy = -1, 0
  -- cima -> baixo
  elseif dir == 2 then
    x = flr(rnd(14) + 2)
    y = 3
    dx, dy = 0, 1
  -- baixo -> cima
  else
    x = flr(rnd(13) + 2)
    y = 15
    dx, dy = 0, -1
  end

  add(ghosts, {
    x = x * 8,
    y = y * 8,
    dx = dx,
    dy = dy
  })
end

function freeze_player()
  p_frozen = true
  freeze_timer = 60 -- 1 segundo
end
-->8
-- tela de titulo

function menu_init()
  music(-1)
  credits_t = 0
  menu_t = 0
  menu_option = 1
  menu_starting = false
  menu_deplay = 80
  menu_blink_t = 0
  fade_table = {0,1,1,5,5,5,5,13,13,13,6,6,6,7}

  moon_init()
  stars_init()
  
  set_state(inicio_update, inicio_draw)
end

function menu_resume()
  menu_t = 0
  menu_option = 1
  menu_starting = false
  menu_blink_t = 0

  moon_init()
  stars_init()

  music(33)

  set_state(menu_update, menu_draw)
end

function inicio_update()
  credits_t += 1
  if credits_t > 140 then
    music(33)
    set_state(menu_update, menu_draw)
  end
end

function inicio_draw()
  cls()
  local idx
  if credits_t <= 100 then
    idx = flr(credits_t) + 1
  else
    local rev_t = credits_t - 100
    idx = 14 - flr(rev_t)
  end
  if idx < 0 then idx = 0 end
  if idx > 14 then idx = 14 end
  
  print_center("um jogo de jefferson neves", 64, fade_table[idx])
  print_center("jeffersonrpn.itch.io", 116, fade_table[idx])   
end

function menu_update()
  menu_t += 1
  moon_update()
  stars_update()
  
  -- se o jogador ainda nao apertou nada
  if not menu_starting then
    if btnp(2) then
      menu_option = max(1,menu_option-1)
    elseif btnp(3) then
      menu_option = min(2,menu_option+1)
    end
end
  if not menu_starting then
    if menu_t > menu_deplay and (btnp(4) or btnp(5)) then
      menu_starting = true
      menu_blink_t = 0
    end
  else
    -- animacao de piscada
   	music(-1)	
    menu_blink_t += 1
    if menu_blink_t > 60 then
      if menu_option == 1 then
        reset_run()
        inter_init()
      else
        credits_init()
      end
    end
  end
end

function menu_draw()
  cls(0)
  map(0, 17)

  stars_draw()
  moon_draw(moon_x, moon_y)
  
  print("\f6\^o2ffturno da meia-noite", 30,38, 8)
  print("2026 jefferson neves", 2, 120, 13)
  
  if menu_t > menu_deplay then
    draw_menu_option(
      "iniciar jogo",
      62,
      menu_option==1
    )
    draw_menu_option(
      "creditos",
      70,
      menu_option==2
    )
  end
end

function draw_menu_option(text,y,selected)
  local x = 64 - #text*2

  if selected then
    local txt_col = 6
    local outline = 1
    -- texto vermelho com outline branco
    if menu_starting then
      if flr(menu_blink_t/4)%2==0 then
        txt_col = 1
        outline = 6
      end
    end
    print(
      "\f"..txt_col..
      "\^o"..outline.."ff"..
      text,
      x,
      y
    )
    local yo = sin(menu_t/16)

    local spr = get_frame(ghost_ani,16,30)

    draw_spr(
      spr,
      x-12,
      y-1+yo,
      false
    )
    draw_spr(
      spr,
      x+#text*4+3,
      y-1+yo,
      true
    )
    else
    -- texto branco normal
    print(text,x,y,7)
  end
end

function moon_init()
  moon_arrived = false
  moon_x = -12
  moon_y = 44
  moon_target_x = 8
  moon_target_y = 24
  moon_speed = 0.2
end

function moon_update()
  if not moon_arrived then
    moon_x += moon_speed
    moon_y -= moon_speed
    if moon_y <= moon_target_y then
      moon_arrived = true
    end
  end
end

function moon_draw(x, y)
  for j = 0, 3 do
    for i = 0, 3 do
      local tile = 64 + i + j*16
      spr(tile, x + i*8, y + j*8)
    end
  end
end

function stars_init()
  stars = {}
  stars_colors = {6,6,6,6,6,6,7,7,7,7,7,7,10,12}
  stars_colors = {6,6,6,6,6,6,7,7,7,7,7,7,10,12}
  for i= 1, 20 do
    add(stars, {
      x = rnd(128),
      y = rnd(75),
      c = 7
    })
  end
end

function stars_update()

		if menu_t % 8 == 0 then
		  local n = #stars_colors
				for s in all(stars) do
		    s.c = stars_colors[flr(rnd(n)) + 1]
		  end
		end
end

function stars_draw()
  for s in all(stars) do
    pset(s.x, s.y, s.c)
  end
end
-->8
-- creditos
anim_time = 18
anim_delay = 5
function credits_init()
  credits_t = 0
  set_state(credits_update,credits_draw)
end

function credits_update()
  credits_t += 1
  if credits_t >= anim_delay*6 + anim_time then
    if btnp(4) or btnp(5) then
      menu_resume()
    end
  end
end

function credits_draw()
  cls(0)
  draw_frame(1, 1, 14, 14, 1, 10)
  print_center("game designer.programador", anim_y(25,0), anim_color(0,7))
  print_center("jefferson neves", anim_y(35,0), anim_color(0,13))
  print_center("arte de capa", anim_y(55,anim_delay*1), anim_color(anim_delay*1,7))
  print_center("emanuelly assueria", anim_y(65,anim_delay*1), anim_color(anim_delay*1,13))
  print_center("musica", anim_y(85,anim_delay*2), anim_color(anim_delay*2,7))
  print_center("robbyduguay", anim_y(95,anim_delay*2), anim_color(anim_delay*2,13))

  if credits_t >= anim_delay*6 + anim_time then
    print("❎/🅾️ voltar", 70, 112, 7)
  end
end

function anim_y(target_y,start_frame)
  local d = mid((credits_t-start_frame)/anim_time,0,1)
  return target_y+10*(1-d)
end

function anim_color(start_frame, final_color)
  local d = mid((credits_t-start_frame)/anim_time,0,1)

  if d < .25 then
    return 0       -- mesma cor do fundo
  elseif d < .5 then
    return 5       -- cinza escuro
  elseif d < .75 then
    return 6       -- cinza claro
  else
    return final_color
  end
end
-->8
-- pre jogo (dicas)

function inter_init()
  set_state(inter_update, inter_draw)
end

function inter_update()
  if btnp(4) or btnp(5) then
    game_init()
  end
end

function inter_draw()
  cls(0)
  draw_frame(1, 4, 14, 7, 1, 44)
  draw_text("a meia-noite, os mortos reinvidicam seu lugar.", 1, 4, 14, 6)
  draw_text("o trabalho do coveiro torna-se essencial.", 1, 6, 14, 6)
  
  -- draw_text("empurre as lapides para seus devidos lugares", 1, 8, 14, 13)
  -- draw_spr(get_frame(p_ani, 8, 0), 46, 86)
  -- spr(19, 56, 86)
  -- print(">>", 66, 88)
  -- spr(22, 76, 86)
  draw_spr(get_frame(o_ani, 12, 0), 96, 76)
  print("/", 105, 78, 6)
  draw_spr(get_frame(x_ani, 12, 0), 110, 76)
end

-->8
-- objetivos

function check_goals()
  local all_correct = true
  
  for tomb in all(tombs) do
    local floor = tile_at(tomb.x, tomb.y)
    local match = tile_match(floor, tomb.fig)
    tomb.done = match
    if not match then
      all_correct = false
    end
  end
  
  if all_correct then
    on_level_complete()
  end
end

function tile_match(tile, fig)
  return fget(tile, fig)
end

function on_level_complete()
  complete_init()
end

function next_level()
  current_level = (current_level or 1) + 1
  if current_level > final_level then
    gameover_init()
  else
    game_init()
  end
end

function on_time_over()
  p_lives -= 1
  morte_init()
end

function reset_run()
  p_lives = 3
  total_time = 0
  current_level = 1
 	final_level = #levels
end

-->8
-- hud

t_hud = 0

function draw_hud()
  local total = #tombs
  local xo = 128 - total * 9
  
  -- limpar
  pal(14, 0)
  for l = 0,15 do
    spr(50, l*8,0)
		end
  pal()
  -- objetivos
  for i, tomb in ipairs(tombs) do
    if tomb.done then
      draw_spr(get_frame(goals_ani, 2, 64), xo + (i - 1) * 9, 0)
    else
      spr(34, xo + (i - 1) * 9, 0)    
    end
  end
  
  -- tempo  
  local bar_x = 10
  local bar_y = 3
  local bar_w = 27
  local bar_h = 1
  
  -- evita divisao por zero
  -- garante intervalo [0,1]
  local time_ratio = 0
  if level_time and level_time > 0 then
    time_ratio = level_timer / level_time
  end
  time_ratio = mid(0, time_ratio, 1) -- clamp entre 0 e 1
  
  local x2 = bar_x + flr(bar_w * time_ratio)
		
  spr(11, 0, 0) -- sol
  spr(12, bar_w + 13, 0) -- lua
  -- barra
  spr(27, 8, 0)
  spr(28, 16, 0)
  spr(28, 24, 0)
  spr(29, 32, 0)
		rectfill(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, 13)
		if x2 > bar_x then
		  rectfill(bar_x, bar_y, x2, bar_y + bar_h, 6)
		end
		
		-- debug
  --	local seconds = flr(level_timer / 60) + 1
		-- print(seconds, bar_x + bar_w + 4, bar_y - 1, 7)
  
  -- vidas
  spr(13, xo - 18, 0)
  local lives = p_lives or -1
  print_r(""..lives, xo - 3, 1, 6)
end
-->8
-- level complete

function complete_init()
  total_time += (level_time - level_timer)
  set_state(complete_update, complete_draw)
end

function complete_update()
  -- aguarda o jogador pressionar x/o para continuar
  if btnp(4) or btnp(5) then
    next_level()
  end
end

function complete_draw()
  -- congela a tela do jogo
  local lvl = levels[current_level]
  cls(0)
  map(lvl.map_x, lvl.map_y, 0, 0, 128, 32)
  
  -- desenha as lapides e o jogador na posicao congelada
  for tomb in all(tombs) do
    spr(tomb.s, tomb.x * 8 + tomb.ox, tomb.y * 8 + tomb.oy)
  end
  draw_spr(get_frame(p_ani, 8, 0), p_x * 8 + p_ox, p_y * 8 + p_oy, p_flip)
  
  draw_hud()
  
  -- mensagem central
  draw_frame(1, 7, 14, 4, 1, 44)
  draw_text("a morte permanece no seu devido lugar.", 1, 7, 14, 6)
  draw_text("por enquanto...", 1, 9, 14, 6)

  draw_spr(get_frame(o_ani, 12, 0), 96, 78)
  print("/", 105, 80, 6)
  draw_spr(get_frame(x_ani, 12, 0), 110, 78)
end

-->8
-- game over

function gameover_init()
  music(43)
  music_playing = false
  gameover_t = 0
  gameover_wait = 500 
  set_state(gameover_update, gameover_draw)
end

function gameover_update()
  gameover_t += 1
  if p_lives > 0 then
    gameover_wait = 200
  else
    gameover_wait = 60
  end
  if gameover_t > gameover_wait and (btnp(5) or btnp(6)) then
    menu_init()
  end
end

function gameover_draw()
  cls(0)
  if p_lives > 0 then
		  draw_frame(1, 2, 14, 8, 13, 16)
		  draw_text("mais uma noite, mais uma labuta.", 1, 2, 14, 7)
		  draw_text("sob sua pa vigilante, nenhum morto voltou.", 1, 4, 14, 7)
		  draw_text("e os vivos dormem em paz.", 1, 7, 14, 7)
		  draw_text("", 1, 6, 14, 6)
		  
		  draw_frame(1, 12, 14, 2, 13, 16)
		  print("tempo de jogo:"..total_time, 16, 102, 7)
		  
		  if gameover_t > gameover_wait then
				  draw_spr(get_frame(o_ani, 12, 0), 96, 70)
			 	 print("/", 105, 72, 7)
				  draw_spr(get_frame(x_ani, 12, 0), 110, 70)
				end
		else
		  draw_frame(1, 4, 14, 7, 1, 44)
		  draw_text("nem toda dedicacao pode deter o retorno dos que deveriam descansar.", 1, 4, 14, 6)
		  draw_text("a escuridao venceu dessa vez.", 1, 8, 14, 6)
		  draw_text("", 1, 6, 14, 6)
		  
		  if gameover_t > gameover_wait then
				  draw_spr(get_frame(o_ani, 12, 0), 96, 76)
			 	 print("/", 105, 78, 6)
				  draw_spr(get_frame(x_ani, 12, 0), 110, 76)
				end
  end
end
-->8
 -- morte

function morte_init()
  death_timer = 0 
  death_waiting = 90
  fade_level = 0
  mark_unsealed_goals()
  set_state(morte_update, morte_draw)
end

function morte_update()
  death_timer += 1

  if death_timer > death_waiting then
    fade_level += 1
    if fade_level <= 15 then
      apply_fade()
    else
      pal()
      if p_lives <= 0 then
        gameover_init()
        return
      end
      game_init()
    end
  end
end

function morte_draw()
  -- desenha a cena (ultimo frame antes da morte)
  draw_game()
  draw_hud()
  apply_fade()
  pal(14, 0)
  for g in all(unsealed) do
    spr(47, g.x * 8, g.y * 8)
    spr(63, g.x * 8, (g.y + 1) * 8)
  end
end

function apply_fade()
 for c = 0, 15 do
   pal(c, max(0, c - fade_level), 1)
 end
end

function mark_unsealed_goals()
  local lvl = levels[current_level]
  unsealed = {}

  -- percorre mapa
  for y = 0, 15 do
    for x = 0, 15 do
      local tile = tile_at(x, y)

      -- verifica flag de tumba
      -- 5, 6, 7
      for fig = 5, 7 do
        if fget(tile, fig) then
          if not tomb_at(x, y) then
            add(unsealed, { x=x, y=y})
          end
        end
      end
    end
  end
end

__gfx__
000000001111111155555555111111111111111111111111111111110dddddddddddddddddddddd000000000000000009000000a002202201111111111555511
000000001111111155555555111111d11111111111111111111111110d66666666666666666666d000000000000dd000090aa000028828821100001115666651
00700700111111115555555511111dd11d11111111111111111111110d77777777777777777777d00000000000d6770000f99a0002888782103bb30156777765
0007700011111111555555551d11dd111dd111111d11111111166111056d666666d666666666d650000000000d6776700a9979a00028882003bb7b3056171165
0007700011111111555555551dd1dd1111dd11d11dd11d111161161105dddddddddddddddddddd50000000000d6777700a9999a00002820003bbbb3056171165
00700700111111115555555511d1d11111dd1d1111d1d11111d66d11056666d6666666d6666d66500000000000d6770000a99a0000002000033bb33056767665
00000000111111115555555511111111111d111111111111111dd11105555555555555555555555000000000000dd000000aa090000000000033330015757751
0000000011111115555555551111111511111115111111151111111500000000000000000000000000000000000000009000000f000000001003300111555511
00222220000000001155551111555511115555117711117777111177771111771111111111555511000000000000000000000000000000001044490155111111
02211112002222201566665115666651156666517111111771111117711111171111111115666651000000000000000000000000000000001104101157551111
22171712022111125662266156662661566226611117711111117111111771111111111156666661000000000077777777777777777777001111111166775555
22171712221717125626226156622261562266611171771111177711117711111111111156ddd661000000000700000000000000000000701111111155566765
02111112221717125622226156662661562666611177771111117111117111111111111156666661000000000700000000000000000000701111111111115751
0022222002111112566226615666266156226661111771111111711111771111111111115666dd61000000000077777777777777777777001111111111111511
02221220002222205666666156666661566226617111111771111117711771171111111156666661000000000000000000000000000000001111111111111111
02211220022212205666666156666661566666617711117777111177771111771111111156666661000000000000000000000000000000001111111111111111
001111000011110066000066660000666600006666000066660000666600006611555511115555110d66d66dd666d6d00055550000000000103013010e3e03e0
016677110166771160000006600000066000000660000006600000066000000615666651156666510d666666666666d00566665008888800100303010ee3e3e0
166777711667777100055000000220000002200000022000000220000002200056666661566666610d777777777777d05677776588e8e8801103030300e3e3e3
1671717116717171005675000028e2000028720000288200002782000028720056ddd66156dd6661056d666666d6665056171165888e888003133303e30333e3
1671717116717171005665000028820000288200002782000028820000288200566666615666666105dddddddddddd505617116588e8e880103355300e33553e
167776711677777100055000000220000002200000022000000220000002200056d6dd6156dddd61056666d666666d5056767665e88888e0103533010e3533e0
167161611616166160000006600000066000000660000006600000066000000656666661566666610555555555555550057577500eeeee001103301100e33e00
0110101001010110660000666600006666000066660000666600006666000066566666615666666100000000000000000055550000000000110dd01100edde00
0011110000111100eeeeeeee111111111111111111111111111111111111111111101101110110111011011100000000000000000000000014e4d44104e4d440
0166771101667711eeeeeeee111111d111111111111111111111111111111111110d00d010d00d010d00d0110bbbbb0000000000000000004d4d4dd44d4d4dd4
1667777116677771eeeeeeee11111dd11d111111111111111111111111111111110655605065560506556011bb333bb00bbbbb00088888001111111100000000
1671717116717171eeeeeeee1d11dd111dd111111d11d11d1111d11d1d111111107767777777677777767701bb3b3bb0bb333bb088e8e8801111111100000000
1671717116717171eeeeeeee1dd1dd1111dd11d11dd1d1dd1111d1dd1dd11d11110d55d050d55d050d55d011bb333bb0bb3b3bb0888e88801111111100000000
1677767116777771eeeeeeee11d1d11111dd1d1111d1d1d111d1d1d111d1d1111106116010611601061160113bbbbb30bb333bb088e8e8801111111100000000
1671616116161661eeeeeeee11111111111d1111111111111111111111111111110611601061160106116011033333000bbbbb00088888001111111100000000
0110101001010110eeeeeeee11111111111111111111111111111111111111111106116010611601061160110000000000000000000000001111111100000000
0000000000000777770000000000000011011011110110111101101110d11d01000000000000000000000000dddddddddddddddd000000000000000000000000
0000000000777777777777700000000010d00d0110d00d0110d00d01106006010dddddddddddddddddddddd0d66666666666666d000000000000000000000000
00000000777777777777666d00000000106556055065560150655605106556010d66666d77777777d66666d0d77777777777777d000000000000000000000000
000000077777777776666666dd0000000d777777777777d0777767770d7777d00d66666d66d66666d66666d056d6666666d66665000000000000000000000000
00000777777777776666666666d0000010d55d0550d55d0150d55d0510d55d010d666665dddddddd566666d05dddddddddddddd5000000000000000000000000
000077777777777666666666666d0000106116011061160110611601106116010d666665666666d6566666d0566666d6666666d5000000000000000000000000
000077777777766666666666666d0000106116011061160110611601106116010d66666555555555566666d05555555555555555000000000000000000000000
0007777777777666666666666666d000105010111101050111011011110110110d6666d0000000000d6666d00000000000000000000000000000000000000000
00777777777766666666666666666d0010d0111111110d0110d01111111111110d6666d0000000000d6666d00000000000000000000000000000000000000000
00777777777666666666666666666d00106011111111060110601111111111110d6666d0000000000d6666d00000000000000000000000000000000000000000
077777777776666666666666666666d0106011111111060110601111111111110d6666d0000000000d6666d00000000000000000000000000000000000000000
077777777766666666666666666666d0106011111111060110601111111111110d6666d0000000000d6666d00000000000000000000000000000000000000000
077777777766666666666666666666d00d760111111067d00d760111111111110d6666d0000000000d6666d00000000000000000000000000000000000000000
7777777777666666666666666666666d106011111111060110601111111111110d6666d0000000000d6666d00000000000000000000000000000000000000000
7777777776666666666666666666666d106011111111060110601111111111110d6666d0000000000d6666d00000000000000000000000000000000000000000
7777777776666666666666666666666d106011151111060510601111000000000d6666d0000000000d6666d00000000000000000000000000000000000000000
7777777776666666666666666666666d10d11d1110d11d0111110d010ddddddd0d66666dddddddddd66666d00000000000000000000000000000000000000000
7777777776666666666666666666666d1060060110600601111106010d6666660d66666666666666666666d00000000000000000000000000000000000000000
077777777666666666666666666666d01065560550655601111106010d7777770d77777777777777777777d00000000000000000000000000000000000000000
077777777766666666666666666666d00d777777777777d011110601056d6666056d666666d6666666d666500000000000000000000000000000000000000000
077777777766666666666666666666d010d55d0550d55d01111067d005dddddd05dddddddddddddddddddd500000000000000000000000000000000000000000
00777777776666666666666666666d00106116011061160111110601056666d6056666d6666666d666666d500000000000000000000000000000000000000000
00777777777666666666666666666d00106116011061160111110601055555550555555555555555555555500000000000000000000000000000000000000000
0007777777766666666666666666d000110110111101101111110601000000000000000000000000000000000000000000000000000000000000000000000000
000077777777666666666666666d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000077777777766666666666666d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000777777776666666666666d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000077777777666666666dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777776666666d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000077777776666dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000007777777d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
81818181818181818181818181818181000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111515555111555555555555555555555555555555555555555551111111111111111115511111111151111115551111111111111111111111111111111111
111115155551555555555555555555dddd5555555555555555555555111111111111111115511111111511111155555111111111111111111111111111111111
111115555d55555555555ddddddddddddddd55555555555555555555551111111111115555511111115511111155555111111115111111111111111111111111
111115555d5555555ddddddddddd6666666ddddddddd555555555555555111111111155551111115555111111555551111111115111111111111111111111111
11111555dd55555ddddddddd677777777777766ddddd555555555555555511111115555511111155551111111555511111111155111111111111111111111111
11511555dd555ddddddddd6777777777777777776dddd55555555555555555555555511111111155111111111555111151111551111111111111111111111155
11555555ddd5dddddddd67777777777777777777776ddd555555555555d555555551111111115555111111115551111551115111111111111111111111111511
11555555dddddddddd67777777777777777777777777dd55555555d5dddd55555551111111155511115551155511111511111111111111111111111111111111
11555555ddddddddd6777777777777777766ddddddd666555555555ddddd55555511111111555511155511555511155511111111111111111111111111111111
15555555dddddddd67777777777777776ddddddddddd5dd5555555ddddd555555551111115555111555115d55111551111111111111111111111111111151111
1555d555ddddddd6777777777777776dddddddddd555555555555ddddd555555555111111551111155111d551111511111111111111111111111111111111111
1555dd5ddddddd6777777777777776ddddddddd5555555555555ddddd5555555555111115111111551155d511111111111111111111111111111111111111111
1555dd55ddddd677777777677767dddddddddddd55555555555dddddd55555555551111111111111115d55511111111111111111111111111111111111111111
1555dd55ddddd77777776488448445dddddddddd5555555555ddddd5555555445511111111111111115555111111111111111111111111111111111111111111
5555dd51d55d67777777666488442ddddddddddddd5555555dddddd555555584111111111111111115d555111111111111111111111111111111111111111111
1555dd15d5dd77777777777788dddddddddddddddddd5555dddd5555555551845111111111111111555551111111111111111111111111111111111111111111
1515dd15d15677777777777744ddddddd5dd55d5d555525ddd555555555122841111211111111115d55511111111111111111111111111151111111101111111
1515dd51d15777777777777744dd484d885584484482484d54888455552488841288845111111115d55511111111111111111111111155511111111111111111
1515dd51556777777777777744ddd84d485584445484484588528455554421841125285111111115d55111111111111111111111111551111111111111111111
1115ddd11d6777777777777744ddd44d4855445dd24554454455845555441144152248111111115d555111111111111111111111111111115111111111111111
1115ddd55d7777777776777644ddd44d445544ddd245544544554455554411441442245111111155551111111111555111111111111111111111111111111111
1115dddd5d7777777767777d44dd4444445544ddd245544544554455554452445445242111555555551111111115551111111111111111111111111111111111
1155dddd1d77677777d7767d442dd4422455445dd245544544442555514442421244445115555555511111111115511111111111111111111111111111111111
1155ddd5567767777dd5ddd152dddd5d55d555ddd55d525dd5555555551251511115111155555555111111111155111111111111111511111111111011111111
1155ddd1567765777dd7777d5ddddddddddddddddddddddd55555555551155555111111555555551111111111551111111111111115511111111111111111111
10155d51d67775777177777ddd55dddddddddddddddddddd55555555555115515111115d55555511111111111511111111151115555111111111111111111111
1115d115d67766776d767776dddddddddddddddddddddddd5555555555511151111111d555555511111111111111111111151151111111111111111111111111
111515ddd6775777566d7776ddddddddddddddddddddddd55555555555511111111115d555555551111111111111111111111551111111111111111111111111
51115dddd676d775d7d77776ddd5ddddddddddddd524445555444455555111241111155555555511111111111111111451111511111111111111111111101111
51015ddddd76d751dd777777ddd5dddddddddddddd4882d555488555555115882115555555555111111111111111114841555111111111111110111111101111
5501dddddd77150d777777776dd55dddddddddddddd4845555484555551111221155555555551111111111551111115215244111111111110111111001111111
5501dddddd6750d7777777777dd1ddddddddddddddd4445555884555515111111555555555511111111115511111111115282111111111111111111110011511
5501dddddd67d1677777776776d5ddddddddddddddd4442554444555284455481524445551111114422825112442212421244421244421111111111111010111
51115dddddd7d17777776d7777d5dddddddddddddd54444554444554824821881148488211111112848882548488412821244412444821111111111111001111
11015dddddd6d5777777d67776dddd5dddddddddddd4424444244554415821481111148124224212842482244118412821244114411821111111555111101111
11115ddddddd1d7777775d51dd555dddddddddddddd44d4445244d52444421441222444124444212421482244118412821244114444421111111515111101111
111555dddd51577777761d6777776dddddddddddddd44d544dd44d52415151441242144111111112421442144114412421244114411011111111111155101011
1015555dd511d77777616777777776dddddddddddd5445d4d6244554455421441244244211111112421442144114412421244114421421111111111551101111
0015555dd11ddd7777d5777dd676dd76dddddddddd2445d67d244252444421441244444111111112421442544442112421244212444421111111111511111011
00155555d11ddd67775d77dddd5d665d76dddddddd42dd776d522555555111521111111111111111111255111111111211111111115111111111115111111010
10155555511dddd67715d157777777d7777766666dd77776ddd55555555511111111111111111111111111111111111111111111115111111100111111111101
101555ddd105dddd671156777677777d677777777777776ddd555551115111111111111111111111111111111111111111111111111111111110111115101101
1011555dd101ddddd6157776677777775d677777777776ddd5222222511111111111111111111115551111111111111111111111111111111111011115101100
111155551001dddddd1677d677677777d77777777777dddd52222222251111111111111111111155551111111111111111111111111111111111011155110000
110111510015ddddd11d66566677777756777777776dddd522222222221111111111111111111555511111111111111111111111111111111111111551110010
11010110001555dd511dd16777777776666777776ddddd5222222222222111111111111111155551111111111111111111111111111111111111101151110010
111111000110111110111ddd667777766777766dddddd52000122222222111111111111111155111111111111111111111111111111111111111110111110000
00111101100100001115ddddddddd666666dddddddddd50000002222222111111111111155551111111111111111111111111111111111111115110011111000
10111101011151115ddddddddddddddddddddddddddd520000000222222211111111111155111111111111111111111111111111111111111151111001111100
100110101555555ddddddddddddddddddddddddddddd500000000012212211111111111111111111111111111111111111111111111111151111111111011110
1011001055555555ddd5dddddddddddddddddddddddd500100051001211151111111111111111111111111111111111111111111111111511111111110100011
10110111555d555555d55dddddddddddddddddddddd510065016d000221115111111111111111111111111111111111111111111111151111111111111100001
10110111555ddd5555555dddddddddddddddddddd5550016d016d000121115111111111111111111111151111111111111111111115511111111111111011110
10101111555dddd5555555ddddddddddddddd55555510006d016d000021115111111111111111111155111111111111111111111155111111111111101115111
11110101555dddddd555555ddddddddddddd55555551000d501d5000011111511111111111111155111111111111111111111111551111111111111111115551
11110101555555dddd5555555dd555ddddd555555511000000000000021111511111111111111111111111111111111111111555511111111111111555511555
111101011555555dddd5555555555555555555555111000000000000021111111111111111111111111111111111111111111111111111111110015555510155
1111010015555555ddddd55555555555555555551112000000000000121111511111111111111111111111111111111111111111111111111111155111551015
111110001155555555dddd5555555555555555111152200000000001211112225111111111111111111111111111111111111111111111111111551555555111
11111001111555555555dd5555555555555555111122210000000002111122222251111111111111111111111111111111111111111111111515551551115551
11100111111555555555555555555555555555111122221000000021111112222221111111111111111111111111111111111111111111115515155511555555
11101115555555555555555555555555555555511122222100001111111122222222111111111111111111111111111111111111111111555511555115555555
11101115555555555555555555555555555555551222222220011111111222222222111111111111111111111111111555511111111155551155555115555555
11001115555555555555555555555555555555555222222112200011111111112222255555555555555555511115555555555555555555555511555155555555
01011555555555555555555555555555555555512222221221200001111222222222255555555555555555555555555555555555555555555555151155555555
01015555555555555555555555555555555555551002212221100001111112222222221555555555555555555555555555555555555555555515111551111555
00115555555555555551555555555555555555550000121111100110111111111111122555555555555555555555555555555555555555555555555555111155
00155555555555555551155555555555555555510000012212110111111222211111112225555555555555555555555555555555555555555555555551155515
00555555555555555555155555555555555555500000002222110112111112222222222222455555555555555555555555555555555555555555555551555551
01555555555555555555115555155555555555100000000222111101221211111222222222225555555dd555555555555555555555ddddddddd5555555115551
015555555555555555555115555155555555550000110001221110011222221111112222222222d5555ddd5dd555555555555555555dd5dd5dd5d55555555555
0015555555555555555555111555115555555100015110012221111011222222211111122222222555555555555555555555d5555d5dd5dd5dd5dd5555555555
001555555555555555555551115511015555100005511000122111110112222222221111122222222555555555555555522222555555555d5555dd55555555d5
00555555555555555555555111115111155555005551110012221111100012222222222211111122222255555555222222222222222555555555555555555555
00155555555555555555555551111111115510055551110011221111110000222222222222222222222222522222222222222222222222555555555555555555
10155555555555555555555555111111555100055552111001221111111000002222222222222222222222222222222222222222222222255155555555555555
10115555155551555555555555511115555551555555111111122111111000000022222222222222222222222222222221111111122222222555555555555555
011555d55d55d55dd55d55d55dd55115d5555dd511555511111222111100000000001224442222222222222222221000000000000000122222555555d55d55d5
001155d55d55d55dd55d55d55dd5555dd5155dd555155555111222111100000000100000122222222222222100000000011111111110000222255555d55d55d5
000155d55d55d55dd5dd55d55dd5d55d515555d555221555111122211100000110001000000000000000000000011111111111111111110012255555555d5555
000015d55d55d55dd51555d55dd5d55d51555dd155221151551122221000001111110010000000000000000111111111111111111111111100225d55551d5555
110015555d55d55dd11515d55d55555dd555555155222151555552221000001111111101110000000000000111111111111011155555551111025555d5511155
001111111555515d511111d55555555dd555155155222122115555220000011211111111111110000000000000000000000010555515555515515555d5511155
1555510111515555511151d51155d555d55555511522212222155551000011122111111111111111000000011110000111111155551155555151555555111155
5555111111015555511111551155d551d55511555522212222211550000112212211111111111211111000001111111111111155551155555111115555111155
555555011011555111111111111551511551115d5522221222211100001122221222112111111122222211100011111111111115111555555111115511111155
55555510110155551111111111151111151111555522211222211100015555551112221222221111222222221110111111111125111555551111111111111155
555555100101555511111155111111115111115555222212222211221155515521552222222222111222222222211111111111211115dd555111111111111555
555555100115555511155555511111115111111155222211222211222255555122551222222222222122222222222215d55111111115dd555555551111111555
55555551111515111115555111111111111111111522222122222222222111122555122222222222222122222222222255511111151551115555555111115555
55555551111111111115555111111111555511111522221122222222222255522511222222222222222222222222222225511111111111115555551111111555
15555551111111111115551555111111555555111522222112222222222225522511222222222222222222222222222222555111111111115555555111111511
15555551111111111115555555111115555555111522222112222222222225552511222222222222222222222222222222225111111111115555d55111111111
5111515111111111111555551511111555555511112222221222222222222255511122222222222222222222222222222222211111111115555d555111111111
111155d5111111111115555511511155155555511122222211222222222222255112222222222222222222222222222222222211111111155555551111111111
111155d5111111111111555511551115155555111152222211222222222222225552222222222222222222222222222222222211111111555dd5551111111111
1111d15d5511111111111555111111151151155111522222212222222222222222222222222222222222222222222225555551151551155555d5551111111111
11115d55dd1111111111111115511111111111111152222221122222222222222222222222222222222222222225522555d51111515111115555511111111111
1111115dd5511111111111111d51111111111111111222222212222222222222222222222222222222222222225555555dd51111555551111115111111111111
111156d51111111111111dddd5511111111111111115222222111222222222222222222222222222222222225555555555551111155555115111111111111111
11111551111155551111156511111111111111111111222222510022221222222211122222222222222222255555555555555511155555dd5111111111111111
111111111155555dd1111151111111111111111111111522222110011111111220111112222222222222221155555555555555555555511d1111155555511111
111111115555555ddd51111111111111111111111111112222251100011111101011111152221222222222111151555555555555555551111115555555555511
111111155555555dddd1111111111111111111111111115222221100001111100011111111115511111521111111115555555555555511111115555d55555551
11111155d55555555dd511111111111111111111111111122522211000111110001111111111155555111111111111155555111115551111155555d5d5555555
1111115dd555555555d511111111111111111111111111152112251100111111011111111111115515151111111111115555111115511111155d555555555555
111111555555555555d5511111111111111115551111111151111511101111111111111111151115151511111155555115511111115111115555555555555555
111111555555555ddd55511111111111115555d51111111111111111111111111111111111515115151511111555ddd5111111111551111555ddd555555555d5
11111155555555dddd5dd511111111111155dddd5111111111111111111111111111111111111555555511111511555d511111111551111555ddddd5515555d5
111111555555dddddd5d5511111111111155ddd5d51111111111111111111111111111111111115555551111155551155111111115511115555dd55555555d55
11111155555d55d55dddd511111111111151ddd5dd511111511111111111111111111111111111555551111555d51555511111111551111555d5555555555555
11111551ddd5555ddddd555111111111111555d5dd5555d5d51111111111111111111111111111555551115dd15ddd5511111111115111115ddd555555555555
111111515dd55555dddd5d5111111111111155555dd5d5ddd5511111111111111111111111511111555111555d515511111111111151111155d5555555555d55
111111555dd55555dd555551111111111151555d5ddd55ddddd511111111111111111111111555055551111111d51111111111111111111115d5555d5555dd55
1111111155555555555555511111111555d5555d5555555d5dd5511111111111111111111111111155551111111dd5111111111515111111155555dd55555515
111111155555d555555555551111155dddd555555555555d55551111111111111111111111111101555111111115d5111111111155511515555555d55555d555
111111155555d555555555555111155ddd5555555555555515151111111111111111111111111101155111111111511111111111151115555555ddd5555d5555
1111111155d5555555555555d511155555555555555555551511115155111111111111111111111115551111111111111111111111115555555ddd55555d5155
1111111155dd555555555d55551515555d555555555555555111115551111111111111111111111115551111111111111111111111115d55555dd55555555151
11111111555555555555555555111555555515151555555551115515155111111111111111111111115511111111111111111111115555555555555555555151
11111151555555555555555111111511555551511155555555115155551111111111111111111111111511111111111111111111115555551555555555555551
111111115d5555555555111111111155155115511155555555515555511111111111111111111111151151111111111111115111111151555555555555555511
1111111115555515115111151111115111111111111555555551555555115111111111111111111111505111111111111115d511111111551555555555555155
11111111151115551111115d5111111111111111111155555551155555151111111111111111111111505111111111111115dd11111111551155555555555555
1111111111111111111115dd511111111111111111111555155115555051111111111111111111111150511111111111111ddd51111111111155151555555115
11111111111111111111155dd51111111111111111111155555555555011111111111111111111111151551111111111115dddd5111111111111155555555511
111111111111111111111111555111111111111111111155555555555111111111111111111111111155151111111111111111ddd1111111111111155555d511
1111111111111111111111111555511111111111111111155555555511111111111111111111111111551551111111111111111ddd5111111111111555555511

__gff__
0000010000000001010100000000010000000202022040800001000000000000000000000000000001010101000000000000000000000000010101000000000000000000010101010101010101000000000000000101010001000100000000000000000001010100010101000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4446464646464646464646464646464544464646464646464646464646464645444646464646464646464646464646454446464646464646464646464646464544464646464646464646464646464645000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
540101010101010101010101010101555401010101010101010101010101015554484949494949494949494949494a55540f01010101010101010101012801555401010101010101010f010101010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
54010101190101010101010f0101015554010601010101010101010101030155545815050101010101010101010f5a55541f010101010101010101010101015554050101010101010101010101010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
54010401010148494a01011f01010155540601444646464501010101010101555468694c010101010101010301015a5554010101010101050101010101010355540144464646464501010101010f0155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5401280129015a165a010101010301555401010115010101010f01010101015554010101010101010101290101015a555401011501010101010101010101015554010101010101010104010101010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
540101011f015a015a010101010101555401010101010101011f01010101015554010101010401010101010101015a55540107080901010101010101010129555401010f010101010101010105010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5401010101015a016849494a010101555401010101280101015801010101015554010101010101010101010101165a555401010101010101010101160101015554010101010101010101010101010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5401484949496a010601175a010101555401010f01010101015801160101015554010101010101010101014b69696a555401040101010101070808080808095554012801291519162817290119010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
54015815010104010148496a0101015554010101010101010158010101190155540f01014446450105010101010101555401010101010101010101050101015554010601060106010601060106010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
540168494949494a015a01010101015554010101010117010158370101010155540101010101010101010101010301555428010101010101010101010f01015554010101010105010501010f01010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
540101010101015a015a01011901015554030164464646010168694c0101015554015417010101010101010f010101555401010101010101030101010101015554010301010501050105010101010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5401010f0104015a015a0101010301555401010101010101010101010101015554016446464646010105011f010101555401011701010101010101010101045554010101010101014446464645010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5401011f0101015a015a01050101015554010101010101010101010101030155540101280101010101010101010101555401070808080808080808080809015554010101010101010104010101011f55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5403010101010168496a01010101015554010101013601010101010101010155540101010128010101010101010101555401010501010101010101010101015554010101010f01010101010101010155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6446464646464646464646464646466564464646464646464646464646464665644646464646464646464646464646656446464646464646464646464646466564464646464646464646464646464665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3939393939393939451818443939393900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1818191818182918663418561818183600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
180f18183318181847180f47182e181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
181837281829181f18181818183e181900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1818181818181818181818183418181800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011800200c0351004515055170550c0351004515055170550c0351004513055180550c0351004513055180550c0351104513055150550c0351104513055150550c0351104513055150550c035110451305515055
010c0020102451c0071c007102351c0071c007102251c007000001022510005000001021500000000001021013245000001320013235000001320013225000001320013225000001320013215000001320013215
003000202874028740287302872026740267301c7401c7301d7401d7401d7401d7401d7301d7301d7201d72023740237402373023720267402674026730267201c7401c7401c7401c7401c7301c7301c7201c720
0030002000040000400003000030020400203004040040300504005040050300503005020050200502005020070400704007030070300b0400b0400b0300b0300c0400c0400c0300c0300c0200c0200c0200c020
00180020176151761515615126150e6150c6150b6150c6151161514615126150d6150e61513615146150e615136151761517615156151461513615126150f6150e6150a615076150561504615026150161501615
00180020010630170000000010631f633000000000000000010630000000000000001f633000000000000000010630000000000010631f633000000000000000010630000001063000001f633000000000000000
001800200e0351003511035150350e0351003511035150350e0351003511035150350e0351003511035150350c0350e03510035130350c0350e03510035130350c0350e03510035130350c0350e0351003513035
011800101154300000000001054300000000000e55300000000000c553000000b5630956300003075730c00300000000000000000000000000000000000000000000000000000000000000000000000000000000
003000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01240020051450c145051450c145051450c145051450c145071450e145071450e145071450e145071450e1450d145141450d145141450d145141450d145141450c145071450c145071450c145071450c14507145
014800202174421740217402274024744247401f7441f7402074420740207401f7401d7401f7401c7441c7402174421740217402274024744247401c7441c7401d7441f740207402274024744247402474024745
012400200e145151450e145151450e145151450e145151450c145131450c145131450c145131450c145131450f145161450f145161450f145161450f145161450e145151450e145151450c145131450c14513145
011200200c1330960509613096131f6330960509615096150c1330960509613096130062309605096050e7130c1330960509613096131f6330960509615096150c1330960509613096130062309605096050e713
014800200c5240c5200c5200c52510524105201052010525115241152011520115251352413520135201352511524115201152011525135241352013520135251452414520145201452013520135201352013525
014800200573405730057300573507734077300773007735087340873008730087350c7340c7300c7300c73505734057300573005735077340773007730077350d7340d7300d7300d7350c7340c7300c7300c735
014800200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013200202005420050200502005520054200502005020055200542005020050200551e0541e0501c0541c05023054230502305023055210542105020054200501c0541c0501c0501c0501c0501c0501c0501c055
0132002025054250502505025055230542305021054210502805428050280502805527054270502305423050250542505025050250551e0541e0501e0501e0552305423050230502305023050230502305023055
0132002010140171401914014140101401714019140141400f14014140171401b1400f14014140171401b1400d1401014015140141400d1401014017140191400d1401014015140141400d140101401714019140
0132002015140191401c1401914015140191401c1401914014140191401b14017140121401414015140191401e1401914015140191401214014140151401914017140141401014012140171401e1401b14017140
013200202372423720237202372523724237202372023725237242372023720237252172421720207242072028724287202872028725257242572023724237202072420720207202072020720207202072020725
0132002028724287202872028725287242872028720287252c7242c7202c7202c7252a7242a72028724287202a7242a7202a7202a725257242572025720257252872428720287202872527724277202772027725
0019002001610016110161101611016110161104611076110b61112611166111b6112061128611306113561138611336112d6112961125611206111c6111861112611106110c6110861104611026110261101611
011e00200c505155351853517535135051553518535175350050015535185351a5350050515535185351a53500505155351c5351a53500505155351c5351a53500505155351a5351853500505155351a53518535
010f0020001630020000143002000f655002000020000163001630010000163002000f655001000010000163001630010000163002000f655002000010000163001630f65500163002000f655002000f60300163
013c002000000090750b0750c075090750c0750b0750b0050b0050c0750e075100750e0750c0750b0750000000000090750b0750c0750e0750c0751007510005000000e0751007511075100750c0751007510005
013c00200921409214092140921409214092140421404214022140221402214022140221402214042140421409214092140921409214092140921404214042140221402214022140221402214022140421404214
013c00200521405214052140521404214042140721407214092140921409214092140b2140b214072140721405214052140521405214042140421407214072140921409214092140921409214092140921409214
013c00202150624506285060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400181862500000000001862518625186251862500000186051862018625000001862500000000001862500000000001862518605186251862518605186250000000000000000000000000000000000000000
010f00200c0730000018605000000c0730000000000000000c0730000000000000000c0730000000000000000c0730000000000000000c0730000000000000000c0730000000000000000c073000000000000000
013c0020025500255004550055500455004550055500755005550055500755007550045500455000550005500255002550045500555004550045500555007550055500555007550095500a550095500755009550
013c00201a54526305155451a5451c545000001a5451c5451d5451c5451a545185451a5450000000000000001a5452100521545180051c5450000018545000001a545000001c545000001a545000000000000000
011e00200557005575025650000002565050050557005575025650000002565000000457004570045750000005570055750256500000025650000005570055750256500000025650000007570075700757500000
013c00200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013c00201d1151a1151a1151d1151a1151a1151c1201c1251d1151a1151a1151d1151a1151a1151f1201f1251d1151a1151a1151d1151a1151a1151c1201c1251d1151a1151a1151d1151a1151a1151f1201f125
011e0020091351500009135000050920515000091350000009145000000920500000071400714007145000000913500000091350000009205000000913500000091450000009205000000c2000c2050020000000
015000200706007060050600506003060030600506005060030600306005060050600206002060030600306007060070600506005060030600306005060050600306003060050600506007060070600706007060
01280020131251a1251f1251a12511125181251d125181250f125161251b125161250e125151251a125151250f125161251b1251612511125181251d125181250e125151251a125151251f1251a125131250e125
01280020227302273521730227301f7301f7301f7301f7352473024735227302273521730217351d7301d7351f7301f7352173022730217302173522730247302673026730267302673500000000000000000000
012800202773027735267302473524730247302473024735267302673524730267352273022730227302273524730247352273021735217302173021730217351f7301f7301f7301f7301f7301f7301f7301f735
015000200f0600f0600e0600e060070600706005060050600c0600c060060600606007060090600a0600e0650f0600f0600e0600e060070600706005060050600c0600a060090600206007060070600706007065
012800200f125161251b125161250e125151251a12515125131251a1251f1251a12511125181251d125181250f125161251b125161250e125151251a12515125131251a1251f1251a125131251a1251f1251a125
012800201a5201a525185201a525135101351013510135151b5201b5251a5201a525185201852515520155251652016525185201a52518520185251a5201b520155201552015520155251f5001f5001f5001f505
012800201f5201f5251d5201b525155101551015510155151d5201d5251b5201d5251a5101a5101a5101a5151b5201b5251a5201a52518520185201552015525165201652016520165251a5001a5001a5001a505
013c00201003500500000001003509000000000e0300e0351003500000000001003500000000000e0000e00511035000000000011035000000000010030100351103500000000001103500000000000400004005
011e00201813518505000001713517505000001513515505000001013010130101350000000000000000000015135000000000010135000000000011500115001150011500111301113011130111350000000000
01180020071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155051550c155081550c155051550c155081550c155051550c155081550c155051550c137081550c155
01180020071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155081550f1370c1550f155
01180020081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155071550e1550a1550e155071550e1550a1550e155071550e1550a1550e155071550e1370a1550e155
011800201305015050160501605016050160551305015050160501605016050160551605015050160501a05018050160501805018050180501805018050180550000000000000000000000000000000000000000
011800201305015050160501605016050160551305015050160501605016050160551605015050160501a0501b0501b0501b0501b0501b0501b0501b0501b0550000000000000000000000000000000000000000
011800201b1301a1301b1301b1301b1301b1351b1301a1301b1301b1301b1301b1351b1301a1301b1301f1301a130181301613016130161301613016130161350000000000000000000000000000000000000000
011800201b1301a1301b1301b1301b1301b1351b1301a1301b1301b1301b1301b1351b1301a1301b1301f1301d1301d1301d1301d1301d1301d1301d1301d1350000000000000000000000000000000000000000
01180020081550f1550c1550f155081550f1550c1550f155081550f1550c1550f155081550f1550c1550f1550a155111550e155111550a155111550e155111550a155111550e155111550a155111550e15511155
011800202271024710267102671026710267152271024710267102671026710267152671024710267102971027710267102471024710247102471024710247150000000000000000000000000000000000000000
01180020227102471026710267102671026715227102471026710267102671026715267102471026710297102b7102b7102b7102b7102b7102b7102b7102b7150000000000000000000000000000000000000000
011800202b720297202b7202b7202b7202b7252b720297202b7202b7202b7202b7252b720297202b7202e72029720277202672026720267202672026720267250000000000000000000000000000000000000000
011800202b720297202b7202b7202b7202b7252b720297202b7202b7202b7202b7252b720297202b7202e7202e7202e7202e7202e7202e7202e7202e7202e7250000000000000000000000000000000000000000
010c00200c133000000061500615176550000000615006150c133000000061500615176550000000615006150c133000000061500615176550000000615006150c13300000006150061517655000000061500615
0118002002070020700207002070040700407004070040700c0700c0700c0700c0700a0700a0700a0700a0700e0700e0700e0700e0700d0700d0700d0700d070100701007010070100700e0700e0700e0700e075
011800200000015540155401554015545115401154011540115451354013540135401354510540105401054010545115401154011540115451054010540105401054513540135401354013545095400954009545
0118002009070090700907009070070700707007070070700907009070090700907002070020700207002070030700307003070030700a0700a0700a0700a0700707007070070700707007070070700707007075
01180020000001054010540105401054511540115401154011545105401054010540105450e5400e5400e5400e545075400754007540075450e5400e5400e5400e54505540055400554005540055400554005545
__music__
01 08004243
00 08014300
00 03014300
00 02030500
00 02030500
00 03414300
00 08014500
00 03040500
00 03020500
00 03020500
02 08010706
01 0a4d0949
00 0a0d090c
00 0a4c0b4c
00 0a0d0e4e
02 0f4d0c09
01 10124316
00 11134316
00 10121416
00 11131516
00 12424316
02 13424316
01 19425b18
00 19175a18
00 19171a18
00 1b425c18
02 1a194318
01 1f1d5e60
00 1f1d5e20
00 1f1d4320
00 221d211e
00 231d211e
02 1c1d2444
01 25262744
00 292a2844
00 2526272b
02 292a282c
01 2d181e24
00 2d181e24
00 2d181e2e
00 2d181e2e
00 2d181e6e
02 2d181e6e
01 2f454305
00 30424305
00 2f324344
00 30334344
00 2f323705
00 30333805
00 31344344
00 36354344
00 31343905
02 36353a05
01 3c423b41
00 3c423b44
00 3c3d3b44
00 3c3d3b44
00 3e523b41
00 3e423b41
00 3e3f3b44
00 3e3f3b44
00 3e013b41
02 3e013b41

