--strictly speaking, contourext.lua isn't a tweakdata file but i'm not changing the functions themselves so /shrug
--[[
Hooks:PostHook(ContourExt,"init","contourext_init_pingmenu",function(self,unit)
	if ContourExt._types.pingmenu_pingunit then 
		return
	end	
	ContourExt._types.pingmenu_pingunit = {
		fadeout = 0.25,
		priority = 1,
--		material_swap_required = true,
--		fadeout_silent = 1,
--		trigger_marked_event = true,
		color = Vector3(1, 0.3, 0)
	}
	ContourExt._types.pingmenu_pingunit_matswap = {
		fadeout = 0.25,
		priority = 1,
		material_swap_required = true,
--		fadeout_silent = 1,
--		trigger_marked_event = true,
		color = Vector3(1, 0.3, 0)
	}
end)

--]]