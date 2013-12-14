CHARACTER = "units/character/character"

require "lua/shared/boot"

local Menu = require "lua/shared/menu"
local Level = require "lua/shared/level"
local U = require "lua/shared/utility"

function Menu:custom_update(dt)
	local action = self:menu {
		title = "",
		items = {
			{key="1", text="Animated Character"},
			{key="esc", text="Exit"}
		}
	}

	if action=="1" then				Sample.set_scene(Level{level="levels/empty", title = ""})
	elseif action == "esc" then		Application.quit()
 	end
end

function Level:custom_update(dt)
	local replay = self.world:replay()

	local action = self:menu {
		title = self.options.title,
		items = {
			{key="r", text = "Ragdoll"},
			{key="esc", text="Exit"}
		}
	}

	if action=="esc" then Sample.menu()
	elseif action=="r" then self.camera_controller:ragdoll()
	elseif action=="f2" then self.debug_timpani = not self.debug_timpani update_debug(self)
 	end
end

Level.custom_controls = {
	{key=U.plat("space", "cross", "a", "tap left"), text="Jump"},
	{key=U.plat("f1", "start", "start", "tap top"), text="Toggle help"}
}