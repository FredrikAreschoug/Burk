Sample.Scene = class(Sample.Scene)
local M = Sample.Scene

local U = require 'lua/shared/utility'

local font = 'core/performance_hud/debug'
local font_material = 'debug'
	
function M:start()
	self.world = Application.new_world(Application.ENABLE_REPLAY)
	self.viewport = Application.create_viewport(self.world, "default")
	self.shading_environment = World.create_shading_environment(self.world, "core/rendering/default_outdoor")

	self.camera_unit = World.spawn_unit(self.world, "core/units/camera")
	
	self.gui = World.create_screen_gui(self.world, "immediate", "material", "core/performance_hud/gui")
	self.world_gui = World.create_world_gui(self.world, Matrix4x4.identity(), 1, 1, "immediate", "material", "core/performance_hud/gui")

	self.current_menu_item = 1

	self.time = 0
	self.animations = {}
	self.triggers = {}
end

function M:shutdown()
	Application.destroy_viewport(self.world, self.viewport)
	World.destroy_shading_environment(self.world, self.shading_environment)
	Application.release_world(self.world)
end

local function draw_text(self, text, size, at, color)
	Gui.text(self.gui, text, font, size, font_material, at, color)
	local min, max = Gui.text_extents(self.gui, text, font, size)
	min = min + at
	max = max + at
	return max.x
end

local function hit_text(self, pos, text, size, at)
	local min, max= Gui.text_extents(self.gui, text, font, size)
	if pos.x < at.x + min.x then return false end
	if pos.x > at.x + max.x then return false end
	if pos.y < at.y + min.y then return false end
	if pos.y > at.y + max.y then return false end
	return true
end

function M:help(t)
	if not Sample.show_help then
		return
	end

	local w,h = Application.back_buffer_size()
	local key_x = w-300
	local desc_x = key_x + 90
	local param_x = desc_x + 170
	local y = h - 65 - 50
	local font_size = 16
	local line_height = 20  
	
	local key_color = Color(255,255,255)
	local desc_color = Color(200,150,150)
	local param_color = Color(150,150,200)

	t.items = t.items or {}
	for i,item in ipairs(t.items) do
		local key = item.key or ""
		local desc = item.text or ""
		local param = tostring(item.param or "")
		
		if Sample.show_help then
			draw_text(self, key, font_size, Vector2(key_x,y), key_color)
			local color = sel==i and selection_color or desc_color
			local x = draw_text(self, desc, font_size, Vector2(desc_x,y), desc_color)
			draw_text(self, param, font_size, Vector2(x+font_size,y), param_color)
		end
		y = y - line_height
	end
end
 
function M:menu(t)
	local w,h = Application.back_buffer_size()
	local key_x = 50
	local desc_x = key_x + 60
	local param_x = desc_x + 170
	local title_y = h-65
	local y = title_y - 50
	local font_size = 16
	local title_font_size = 40
	local line_height = 20  
	
	local key_color = Color(255,255,255)
	local title_color = Color(255,255,255)
	local desc_color = Color(200,150,150)
	local selection_color = Color(200,255,0)
	local param_color = Color(150,150,200)
	local back_color = Color(128,0,0,0)
	local touch_color = Color(255,255,0,0)
	
	local result = nil

	if Sample.show_help then
		local w,h = Application.back_buffer_size()
		Gui.rect(self.gui, Vector3(0,0,-10), Vector2(w,h), back_color)
	end

	if Sample.show_help and t.title then
		draw_text(self, t.title, title_font_size, Vector2(key_x,title_y), title_color)
	end

	local sel = self.current_menu_item
	if not sel then sel = 1 end
	if sel > #t.items then sel = 1 end
	if sel < 1 then sel = #t.items end

	local enabled_items = {}
	for i,item in ipairs(t.items or {}) do
		if not item.disabled then
			table.insert(enabled_items, item)
		end
	end

	local touch_pos = nil
	local touch_up
	local touch = U.touch_interface()

	if U.use_touch() then
		sel = nil
		if touch.num_contacts() > 0 then
			local id = touch.contacts()
			touch_pos = touch.location(id)
			touch_up = touch.is_touch_up(id)
		end
	end

	for i,item in ipairs(enabled_items) do
		local key = item.key or ""
		local desc = item.text or ""
		local enabled = item.enabled or true
		local param = tostring(item.param or "")
		
		if Sample.show_help then
			if U.is_pc() then
				draw_text(self, key, font_size, Vector2(key_x,y), key_color)
			end
			if touch_pos and hit_text(self, touch_pos, "{ " .. desc .. " }", font_size, Vector2(desc_x, y)) then
				sel = i
			end
			local color = sel==i and selection_color or desc_color
			local x = draw_text(self, sel==i and "{ " .. desc .. " }" or desc, font_size, Vector2(desc_x,y), color)
			draw_text(self, param, font_size, Vector2(x+font_size,y), param_color)
		end
		y = y - line_height

		local ki = Keyboard.button_index(key)
		if ki and Keyboard.pressed(ki) then
			result = key
		end
	end

	local select = function (s)
		local b = Keyboard.button_index("enter") if b and Keyboard.pressed(b) then return true end
		local b = Pad1.button_index("cross") if b and Pad1.pressed(b) then return true end
		local b = Pad1.button_index("a") if b and Pad1.pressed(b) then return true end
		return touch_up
	end
	
	local down = function (s)
		local b = Keyboard.button_index("down") if b and Keyboard.pressed(b) then return true end
		local b = Pad1.button_index("d_down") if b and Pad1.pressed(b) then return true end
		return false
	end
	
	local up = function (s)
		local b = Keyboard.button_index("up") if b and Keyboard.pressed(b) then return true end
		local b = Pad1.button_index("d_up") if b and Pad1.pressed(b) then return true end
		return false
	end

	local help = function (s)
		local b = Keyboard.button_index("f1") if b and Keyboard.pressed(b) then return true end
		local b = Pad1.button_index("start") if b and Pad1.pressed(b) then return true end
		local w,h = Gui.resolution()
		for _,id in ipairs{touch.contacts()} do
			if touch.is_touch_down(id) and touch.location(id).y > h-50 then
				return true
			end
		end
		return false
	end
		
	if Sample.show_help and sel and select() then
		return t.items[sel].key
	elseif Sample.show_help and (down() or up()) and sel then
		local dir = down() and 1 or -1
		sel = sel + dir
		if sel >= 1 and sel <= #enabled_items and not enabled_items[sel].key then
			sel = sel + dir
		end
	elseif help() then
		Sample.show_help = not Sample.show_help
	end

	if sel then
		self.current_menu_item = sel
	end
	
	return result
end

function M:update(dt)
	local replay = self.world:replay()

	if not replay or not replay:is_playing_back() then
		self.time = self.time + dt

		for f,_ in pairs(self.animations) do
			f(dt)
		end
		for f,time in pairs(self.triggers) do
			if self.time > time then
				f(dt)
				self.triggers[f] = nil
			end
		end
	else
		replay:set_frame(replay:frame() + 1)
	end
	self.world:update(dt)
end

function M:render()
	ShadingEnvironment.blend(self.shading_environment, {"default", 1})
  	ShadingEnvironment.apply(self.shading_environment)
  	local camera = Unit.camera(self.camera_unit, "camera")
	Application.render_world(self.world, camera, self.viewport, self.shading_environment)
end

function M:add_animation(f)
	self.animations[f] = true
end

function M:remove_animation(f)
	self.animations[f] = nil
end

function M:add_trigger(when, f)
	self.triggers[f] = self.time + when
end

return M