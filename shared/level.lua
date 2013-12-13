local Scene = require 'lua/shared/scene'
local Character = require 'lua/shared/character'
local U = require 'lua/shared/utility'

Sample.Level = class(Sample.Level, Scene)
local M = Sample.Level

function M:init(options)
	self.options = options
end

function M:start()
	Scene.start(self)

	local options = self.options

	-- Setup camera
	local camera = Unit.camera(self.camera_unit, "camera")
	Camera.set_local_position(camera, self.camera_unit, Vector3(0,0,2))
	Camera.set_local_rotation(camera, self.camera_unit, Quaternion.look(Vector3(0,1,0)))

	-- Load level
	local level
	if options.level then
		level = World.load_level(self.world, options.level)
		Level.spawn_background(level)
		Level.trigger_level_loaded(level)
		if Level.has_data(level, "shading_environment") then
			World.set_shading_environment(self.world, self.shading_environment, Level.get_data(level, "shading_environment"))
		end
	else
		World.spawn_unit(self.world, "core/editor_slave/units/skydome/skydome")
	end
	self.level = level

	self.camera_controller = Character(self.world, self.camera_unit)

	if self.custom_start then
		self:custom_start()
	end
end

function M:update(dt)
	local replay = self.world:replay()

	if not replay or not replay:is_playing_back() then
		self.camera_controller:update(dt)
	end

	Scene.update(self, dt)

	self:help {
		items = self.custom_controls or {
			{key=U.plat("space", "cross", "a", "tap left"), text="Jump"},
			{key=U.plat("ctrl", "circle", "b", "tap right"), text="Crouch"},
			{key=U.plat("f1", "start", "start", "tap top"), text="Toggle help"}
		}
	}

	if self.custom_update then
		self:custom_update(dt)
	end
end

function M:render()
	ShadingEnvironment.blend(self.shading_environment, {"default", 1})
  	ShadingEnvironment.apply(self.shading_environment)
  	local camera = Unit.camera(self.camera_unit, "camera")
	Application.render_world(self.world, camera, self.viewport, self.shading_environment)
end

return M