CHARACTER = "units/character/character"

require "lua/shared/boot"

local Menu = require "lua/shared/menu"
local Level = require "lua/shared/level"
local U = require "lua/shared/utility"

function Menu:custom_update(dt)
	local action = self:menu {
		title = "Bitsquid Animation Sample",
		items = {
			{key="1", text="Animated Character"},
			{key="esc", text="Exit"}
		}
	}

	if action=="1" then				Sample.set_scene(Level{level="levels/empty", title = "Animated Character"})
	elseif action == "esc" then		Application.quit()
 	end
end

function Level:custom_update(dt)
	local replay = self.world:replay()

	local action = self:menu {
		title = (replay and replay:is_playing_back()) and "Replay" or self.options.title,
		items = {
			{key="r", text = "Ragdoll"},
			replay and {key="p", text = (replay and replay:is_playing_back()) and "Stop Replay" or "Start Replay"} or {},
			{key="esc", text="Exit"}
		}
	}

	if action=="esc" then Sample.menu()
	elseif action=="r" then self.camera_controller:ragdoll()
	elseif action=="p" then 
		if replay:is_playing_back() then
			replay:stop_playback()
		else
			replay:start_playback()
		end
	elseif action=="f2" then self.debug_timpani = not self.debug_timpani update_debug(self)
 	end
end

Level.custom_controls = {
	{key=U.plat("space", "cross", "a", "tap left"), text="Jump"},
	{key=U.plat("f1", "start", "start", "tap top"), text="Toggle help"}
}