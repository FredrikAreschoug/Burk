local Level = require 'lua/shared/level'
local Scene = require 'lua/shared/scene'
local U = require 'lua/shared/utility'

Sample.Menu = class(Sample.Menu, Scene)
local M = Sample.Menu

local font = FONT or 'core/performance_hud/debug'
local font_material = 'debug'
	
function M:start()
	Scene.start(self)
	self.skydome = World.spawn_unit(self.world, "core/editor_slave/units/skydome/skydome")

	if self.custom_start then 
		self:custom_start() 
	end
end

function M:update(dt)
	Scene.update(self,dt)

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