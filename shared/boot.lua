-- Project namespace
Sample = Sample or {}

require 'lua/shared/class'
require 'lua/shared/flow_callbacks'
local Menu = require 'lua/shared/menu'
local Level = require 'lua/shared/level'
local U = require 'lua/shared/utility'

function Sample.set_scene(scene)
	if Sample.scene then
		Sample.scene:shutdown()
	end
	Sample.scene = scene
	if Sample.scene then
		Sample.scene:start()
	end
end

function Sample.menu()
	Sample.set_scene(Menu())
end

function init()
	if Window then -- how to make cursor visible and confined in window?
		Window.set_focus()
		Window.set_mouse_focus(true)
--		Window.set_clip_cursor(true)
		Window.set_show_cursor(true)
	end

	if custom_init then
		custom_init()
	end

	if LEVEL_EDITOR_TEST then
		Application.autoload_resource_package("__level_editor_test")
		Sample.set_scene(Level {level = "__level_editor_test"})
		
		-- Copy camera data from application (set by level editor) if any
		-- if Application.has_data("camera") then
		--	Camera.set_local_pose(self.camera, self.camera_unit, Application.get_data("camera"))
		--end
	else
		Sample.show_help = true
		Sample.menu()
	end
end

function shutdown()
	if Sample.scene then
		Sample.scene:shutdown()
		Sample.scene = nil
	end

	if custom_shutdown then
		custom_shutdown()
	end
end

function update(dt)
	if Keyboard.pressed(Keyboard.button_index('f5')) then
		LEVEL_EDITOR_EXIT_TEST = true
	end

	if LEVEL_EDITOR_TEST and LEVEL_EDITOR_EXIT_TEST then
		-- Application.set_data('camera', Camera.local_pose(game.camera, game.camera_unit))
		Application.console_send { type = 'stop_testing' }
	end

	if Sample.scene then
		Sample.scene:update(dt)
	end
end

function render()
	if Sample.scene then
		Sample.scene:render()
	end
end