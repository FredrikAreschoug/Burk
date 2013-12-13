Sample.Character = class(Sample.Character)
local M = Sample.Character

local U = require 'lua/shared/utility'

local walk_speed = 5.0
local run_speed = 15.0
local free_flight_speed = 20.0
local rotation_speed = 1.0
local jump_velocity = 5.0
local glue_translation_speed = -2
local gravity = 9.82
local camera_offset = 1.7
local crouching_camera_offset = 0.8
local camera_behind = 5.0

local crouch_test_offset = 0.11
local mover_height = 2
local mover_radius = 0.5
local max_climb_height = 0.3

function M:init(world, camera_unit)
	self.world = world
	self.camera_unit = camera_unit

	self.unit = World.spawn_unit(world, CHARACTER or "units/character")
	if Unit.set_animation_logging then
		Unit.set_animation_logging(self.unit, true)
	end
	if self.world:replay() then
		self.world:replay():set_unit_record_mode(self.unit, Replay.RECORD_MODE_SCENE_GRAPH)
	end
	self.mover = Unit.mover(self.unit)
	self.crouching = false

	self.camera_mode = "third-person"
	self.mover_mode = "normal"
	self.velocity = Vector3Box()
end

local touch_state = {
	-- Contact id for pan controller
	pan_id = nil,

	-- Contact id for move controller
	move_id = nil,
}

local function get_input()
	local input = {
		pan = Vector3(0,0,0),
		move = Vector3(0,0,0)
	}
	if U.is_pc() then
		input.pan = Mouse.axis(Mouse.axis_index("mouse"))
		input.move = Vector3 (
			Keyboard.button(Keyboard.button_index("d")) - Keyboard.button(Keyboard.button_index("a")),
			Keyboard.button(Keyboard.button_index("w")) - Keyboard.button(Keyboard.button_index("s")),
			0
		)
		input.jump = Keyboard.pressed(Keyboard.button_index("space"))
		input.crouch = Keyboard.pressed(Keyboard.button_index("left ctrl"))
		input.run = Keyboard.button(Keyboard.button_index("left shift")) > 0
	elseif Sample.show_help then
		input.pan = Vector3(0,0,0)
		input.move = Vector3(0,0,0)
	end
	return input
end

local function compute_rotation(self, input, dt)
	local camera = Unit.camera(self.camera_unit, "camera")
	local qo = Camera.local_rotation(camera, self.camera_unit)
	local cm = Matrix4x4.from_quaternion(qo)

	local q1 = Quaternion( Vector3(0,0,1), -Vector3.x(input.pan) * rotation_speed * dt )
	local q2 = Quaternion( Matrix4x4.x(cm), -Vector3.y(input.pan) * rotation_speed * dt )
	local q = Quaternion.multiply(q1, q2)
	local qres = Quaternion.multiply(q, qo)
	return qres
end

local function compute_translation(self, input, dt)
	if Unit.has_animation_state_machine(self.unit) then
		local moving = Vector3.length(input.move) > 0
		if moving ~= self.moving then
			self.moving = moving
			if moving then
				Unit.animation_event(self.unit, "move")
			else
				Unit.animation_event(self.unit, "idle")
			end
		end
	end

	local move = Vector3(0,0,0)

	local pose = Unit.local_pose(self.unit, 0)
	local pos = Unit.local_position(self.unit, 0)
	Matrix4x4.set_translation(pose, Vector3(0,0,0))
	local local_move = input.move*dt * (input.run and run_speed or walk_speed)
	move = Matrix4x4.transform(pose, local_move)

	local slippery = false
	local a = Mover.actor_colliding_down(self.mover)
	if a then
		local u = Actor.unit(a)
		slippery = Unit.has_data(u, "slippery") and Unit.get_data(u, "slippery")
	end

	if Mover.standing_frames(self.mover) > 0 and not slippery then
		if input.jump then
			self.velocity:store(0,0,jump_velocity)
			self.jumping = true
		else
			self.jumping = false
			self.velocity:store(0,0,0)
			move.z = move.z + glue_translation_speed * dt
		end
		self.last_standing_z = pos.z
		self.disable_movement = false
	else
		local v = self.velocity:unbox()
		v.z = v.z - dt * gravity
		self.velocity:store(v)

		-- If we have climbed more than max_climb_height above our last standing position, disable movement
		if self.last_standing_z and pos.z - self.last_standing_z > max_climb_height and not self.jumping then
			self.disable_movement = true
		end
		if self.disable_movement then
			move = Vector3(0,0,0)
		end
		if slippery then
			move = move / 5
		end
	end
	
	local v = self.velocity:unbox()
	move = move + dt*v

	if slippery or self.on_edge then
		Mover.set_max_slope_angle(self.mover, 0.01)
	else
		Mover.set_max_slope_angle(self.mover, math.pi/4)
	end

	Mover.move(self.mover, move, dt)
	return Mover.position(self.mover)
end

local function compute_free_flight_translation(self, q, input, dt)
	local pose = Matrix4x4.from_quaternion(q)
	local pos = Unit.local_position(self.unit, 0)
	local local_move = input.move * dt * free_flight_speed
	local move = Matrix4x4.transform(pose, local_move)
	return pos + move
end

function M:update(dt)
	local input = get_input()

	if input.crouch then
		if not self.crouching then
			self.mover = Unit.set_mover(self.unit, "crouch")
			self.crouching = true
		elseif Unit.mover_fits_at(self.unit, "default", Mover.position(self.mover)) then
			self.mover = Unit.set_mover(self.unit, "default")
			self.crouching = false
		else 
			print "doesn't fit"
		end
	end

	if self.mover_mode == "edge-slip" then
		local cb = function (hit)
			self.on_edge = not hit
		end
		local p = Mover.position(self.mover) + Vector3(0,0, 0.1)
		local ray = Unit.world(self.unit):physics_world():make_raycast(cb, "any")
		Raycast.cast(ray, p, Vector3(0,0,-1), 0.5)
	end

	local q = compute_rotation(self, input, dt)
	local p
	if self.camera_mode == "free-flight" then
		p = compute_free_flight_translation(self, q, input, dt)
	else
		p = compute_translation(self, input, dt)
	end

	local rot_x = Quaternion.rotate(q, Vector3(1,0,0))
	rot_x.z = 0
	rot_x = Vector3.normalize(rot_x)
	local angle = math.atan2(rot_x.y, rot_x.x)
	local project_q = Quaternion(Vector3(0,0,1), angle)

	local pose = Matrix4x4.from_quaternion_position(project_q,p)
	Unit.set_local_pose(self.unit, 0, pose)

	local cam_pose = Matrix4x4.from_quaternion(q)
--	local cam_pose = Matrix4x4.from_quaternion(Quaternion.look(Vector3(0,0,-1), Vector3(0,1,0)))
	local cam_p
	if self.camera_mode == "first-person" then
		if self.crouching then
			cam_p = p + Vector3(0,0,crouching_camera_offset)
		else
			cam_p = p + Vector3(0,0,camera_offset)
		end
	elseif self.camera_mode == "third-person" then
--		cam_p = p + Vector3(0,0,camera_offset) - Matrix4x4.y(cam_pose)*camera_behind
		cam_p = p + Vector3(0,camera_offset,0) - Matrix4x4.y(cam_pose)*camera_behind
	elseif self.camera_mode == "free-flight" then
		cam_p = p + Vector3(0,0,camera_offset)
	end
	Matrix4x4.set_translation(cam_pose, cam_p)
	local camera = Unit.camera(self.camera_unit, "camera")
	Camera.set_local_pose(camera, self.camera_unit, cam_pose)
	local tw = Unit.world(self.unit):timpani_world()
	tw:set_listener(0, cam_pose)
	tw:set_listener_mode(0, TimpaniWorld.LISTENER_3D)
	PhysicsWorld.set_observer(Application.main_world():physics_world(), cam_pose)

	local p1 = Matrix4x4.translation(pose) + Vector3(0.1,0,2)
	local p2 = p1 + Matrix4x4.y(pose)
	local replay = self.world:replay()
	if replay then
		replay:record_debug_line(Color(255,0,0), p1, p2)
		replay:record_screen_debug_text(Color(255,255,255), Vector2(100,100), "campos:" .. tostring(cam_p))
		replay:record_world_debug_text(Color(255,255,255), p1, "campos:" .. tostring(cam_p))
	end
end

function M:cycle_camera_mode()
	local modes = {"third-person", "first-person", "free-flight"}
	for i=1,#modes-1 do
		if self.camera_mode == modes[i] then
			self.camera_mode = modes[i+1]
			return
		end
	end
	self.camera_mode = modes[1]
end

function M:cycle_mover_mode()
	local modes = {"normal", "edge-slip"}
	for i=1,#modes-1 do
		if self.mover_mode == modes[i] then
			self.mover_mode = modes[i+1]
			return
		end
	end
	self.mover_mode = modes[1]
end

function M:ragdoll()
	if self.is_ragdoll then
		Unit.animation_event(self.unit, "reset")
	else
		Unit.animation_event(self.unit, "ragdoll")
	end
	self.is_ragdoll = not self.is_ragdoll
end

function M:position()
	local camera = Unit.camera(self.camera_unit, "camera")
	return Camera.world_position(camera, self.camera_unit)
end

return M