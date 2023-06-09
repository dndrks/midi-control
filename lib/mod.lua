local mod = require 'core/mods'

local selected_port = 1
local device_names
local panic_draw = false
local actions = {'ALL NOTES OFF (K3)'}
local selected_action = 1
local show_panicking = false

mod.hook.register("script_pre_init", "midi-controls-init", function()
  selected_port = 1
  selected_action = 1
  device_names = {}
  for i = 1,16 do
    device_names[i] = midi.vports[i].name
  end
end)

local line = 1

local function midi_panic()
  print('sending CC 120 and CC 123 to port: '..selected_port, midi.vports[selected_port].name)
  midi.vports[selected_port]:cc(120,0,1) -- CC 120 is All Sound Off
  midi.vports[selected_port]:cc(123,0,1) -- CC 123 is All Notes Off
  if clock.threads[panic_draw] then clock.cancel(panic_draw) end
  show_panicking = true
  panic_draw = clock.run(
    function()
      for i = 0,10 do
        panic_draw_pixel = i*12
        clock.sleep(0.05)
        mod.menu.redraw()
      end
      show_panicking = false
      mod.menu.redraw()
    end
  )
end

local m = {}

m.key = function(n, z)
  if n == 2 and z == 1 then
    -- return to the mod selection menu
    mod.menu.exit()
  elseif n==3 and z==1 then
    if line == 2 then
      midi_panic()
    end
  end
end

m.enc = function(n, d)
  if n == 2 then
    line = util.clamp(line+d,1,2)
  elseif n == 3 then
    if line == 1 then
      selected_port = util.clamp(selected_port+d,1,16)
    elseif line == 2 then
      selected_action = util.clamp(selected_action+d,1,#actions)
    end
  end
  mod.menu.redraw()
end

m.redraw = function()
  screen.clear()
  screen.level(15)
  screen.move(0,10)
  screen.text("MIDI CONTROL")
  screen.level(5)
  screen.move(0,20)
  screen.text("E2: NAV / E3: CYCLE SELECTED")
  screen.level(line == 1 and 15 or 3)
  screen.move(0,30)
  screen.text("device")
  screen.move(40,30)
  screen.text(selected_port..': '..midi.vports[selected_port].name)
  screen.level(line == 2 and 15 or 3)
  screen.move(0,40)
  screen.text("action")
  screen.move(40,40)
  screen.text(actions[selected_action])
  if show_panicking then
    screen.pixel(panic_draw_pixel,54)
    screen.pixel(panic_draw_pixel,55)
    screen.pixel(panic_draw_pixel+1,54)
    screen.pixel(panic_draw_pixel+1,55)
    screen.fill()
  end
  screen.update()
end

m.init = function() end -- on menu entry, ie, if you wanted to start timers
m.deinit = function() end -- on menu exit

-- register the mod menu

mod.menu.register(mod.this_name, m)

local api = {}

api.get_state = function()
  return state
end

return api