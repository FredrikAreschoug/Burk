require "lua/shared/boot"

local Menu = require "lua/shared/menu"
local Level = require "lua/shared/level"
local U = require "lua/shared/utility"

function Menu:custom_update(dt)
	Sample.show_help = true
	local action = self:menu {
		title = "Bitsquid Empty Sample",
		items = {
			{key="1", text="Empty level"},
			{key="esc", text="Exit"}
		}
	}

	if action=="1" then				Sample.set_scene(Level{level="levels/empty", title = "Empty Level"})
	elseif action == "esc" then		Application.quit()
	end
end

function Level:custom_update(dt)
	local action = self:menu {
		title = self.options.title,
		items = {
			{key="esc", text="Exit"}
		}
	}

	if action=="esc" then Sample.menu()
	elseif action=="f2" then self.debug_timpani = not self.debug_timpani update_debug(self)
	end
end