Sample.Utility = Sample.Utility or {}
local M = Sample.Utility

function M.is_pc()
	return Application.platform() == Application.WIN32 or Application.platform() == Application.MACOSX
end

function M.use_touch()
	local p = Application.source_platform()
	return p == Application.ANDROID or p == Application.IOS
end

function M.touch_interface()
	if M.use_touch() and Application.platform() == Application.WIN32 then
		return SimulatedTouchPanel
	else
		return TouchPanel
	end
end

function M.plat(pc, ps3, x360, touch)
	if M.use_touch() then return touch end

	local p = Application.platform()
	if p == Application.PS3 then return ps3 end
	if p == Application.X360 then return x360 end
	return pc
end

return M