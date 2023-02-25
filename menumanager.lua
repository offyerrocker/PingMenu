
QuickChat = QuickChat or {
	_radial_menu_manager = nil, --for reference
	_lip = nil 					--for reference
}
QuickChat._mod_path = ModPath
QuickChat._save_path = SavePath .. "quickchat.ini"
QuickChat.settings = {
} --general user pref

local a_t,a_r = tweak_data.hud_icons:get_icon_data("wp_c4")
local b_t,b_r = tweak_data.hud_icons:get_icon_data("wp_talk")
local c_t,c_r = tweak_data.hud_icons:get_icon_data("wp_crowbar")
local d_t,d_r = tweak_data.hud_icons:get_icon_data("frag_grenade")
local e_t,e_r = tweak_data.hud_icons:get_icon_data("equipment_doctor_bag")
local f_t,f_r = tweak_data.hud_icons:get_icon_data("equipment_bank_manager_key")
local g_t,g_r = tweak_data.hud_icons:get_icon_data("equipment_cable_ties")
QuickChat.radial_menus = {} --generated radial menus
QuickChat._radial_menu_params = { --ungenerated radial menus; populated with user data
	{
		id = "quickchat",
	--	title = "",
	--	desc = "",
	--	localized = true,
		size = 300,
		deadzone = 0,
		texture_highlight = "guis/textures/radial_menu/highlight",
		texture_darklight = "guis/textures/radial_menu/darklight",	
		texture_cursor = "guis/textures/radial_menu/cursor",
		callback_open = nil,
		callback_close = nil,
		focus_alpha = 1,
		unfocus_alpha = 0.5,
		item_margin = 0.2,
		items = {
			{
	--			title = "",
	--			localized = true,
				texture = a_t,
				texture_rect = a_r,
				keep_open = false,
				color = Color.red,
				text = "c4",
				font = tweak_data.menu.pd2_medium_font,
				font_size = 32,
				callback = function(index,item_data)
--					item_data.highlight:set_visible( not item_data.highlight:visible() )
					QuickChat:SendChat(item_data.label:text())
				end
			},
			{
	--			title = "",
	--			localized = true,
				texture = b_t,
				texture_rect = b_r,
				text = "talk",
				color = Color.green,
				callback = function(index,item_data)
--					item_data.highlight:set_visible( not item_data.highlight:visible() )
					QuickChat:SendChat(item_data.label:text())
				end
			},
			{
	--			title = "",
	--			localized = true,
				texture = c_t,
				texture_rect = c_r,
				text = "crowbar",
				callback = function(index,item_data)
--					item_data.highlight:set_visible( not item_data.highlight:visible() )
					QuickChat:SendChat(item_data.label:text())
				end
			}
			,
			{
	--			title = "",
	--			localized = true,
				texture = d_t,
				texture_rect = d_r,
				text = "frag",
				callback = function(index,item_data)
--					item_data.highlight:set_visible( not item_data.highlight:visible() )
					QuickChat:SendChat(item_data.label:text())
				end
			}
			,
			{
	--			title = "",
	--			localized = true,
				texture = e_t,
				texture_rect = e_r,
				text = "docbag",
				callback = function(index,item_data)
--					item_data.highlight:set_visible( not item_data.highlight:visible() )
					QuickChat:SendChat(item_data.label:text())
				end
			},
			{
	--			title = "",
	--			localized = true,
				texture = f_t,
				texture_rect = f_r,
				text = "keycard",
				callback = function(index,item_data)
--					item_data.highlight:set_visible( not item_data.highlight:visible() )
					QuickChat:SendChat(item_data.label:text())
				end
			},
			{
	--			title = "",
	--			localized = true,
				texture = g_t,
				texture_rect = g_r,
				text = "zipties",
				callback = function(index,item_data)
--					item_data.highlight:set_visible( not item_data.highlight:visible() )
					QuickChat:SendChat(item_data.label:text())
				end
			}
			--]]
		}
	}
}

QuickChat.input_cache = {}
QuickChat.bindings = {
	pc = {
		["j"] = 1
	},
	ps3 = {},
	ps4 = {},
	xb1 = {},
	xbox360 = {
		["left"] = 1
	},
	gamepad = {},
	vr = {},
	steam = {}
}

function QuickChat:CreateMenu()
	local wrapper_type = managers.controller:get_default_wrapper_type()
--	self._wrapper_type = wrapper_type
	self._gamepad_mode_enabled = wrapper_type ~= "pc"
	
	local binding_data = self.bindings[wrapper_type]
	if binding_data then
		for button_name,radial_index in pairs(binding_data) do
			local button_name_ids = Idstring(button_name)
			self.input_cache[button_name_ids] = {index = radial_index,state = false}
			if not self.radial_menus[radial_index] then
				local radial_menu_params = self._radial_menu_params[radial_index]
				local new_menu = self._radial_menu_manager:NewMenu(radial_menu_params)
				self.radial_menus[radial_index] = new_menu
			end
		end
	end
	--[[
	for i=1,14,1 do 
		local controller = Input:controller(i)
		if controller.type_name and controller.type_name ~= "VirtualController" then
			self._controller = controller
		end
	end
	if self._controller then
		self._controller:add_trigger("left_shoulder",function() _G.Console:Log("Hello") end)
		BeardLib:AddUpdater("quickchat_update_keyboard_input",callback(self,self,"Update"))
	end
	--]]
	
	--[[
	local controller
	local player = managers.player:local_player()
	if alive(player) then 
		local state = player:movement():current_state()
		controller = state._controller
	end
	controller = controller or managers.system_menu:_get_controller()
	controller:add_trigger("confirm",function() Log("confirm") end)
	controller:add_trigger("d_left",function() Log("d left") end)
	controller:add_trigger("left_shoulder",function() Log("left shoulder") end)
	--]]
	BeardLib:AddUpdater("quickchat_update_keyboard_input",callback(self,self,"Update"))
end

function QuickChat:Update(t,dt)
	--[[
	local i = 0
	for buttonname,inputname in pairs(buttons) do 
		i = i + 1
		Console:SetTracker(string.format("%s %s",buttonname,tostring(controller:down(Idstring(buttonname)))),i)
	end
	
	do return end
	--]]
	
	if self._gamepad_mode_enabled then 
		local player = managers.player:local_player()
		if alive(player) then 
			local state = player:movement():current_state()
			local _controller = state._controller or managers.system_menu:_get_controller()
			local ci = _controller._id
			controller = Input:controller(ci)
		end
	else
		controller = Input:keyboard()
	end
	
	if not controller then return end
	
	for button_name_ids,input_data in pairs(self.input_cache) do 
		local menu = self:GetMenu(input_data.index)
		local state = controller:down(button_name_ids)
		if menu then
			if state then 
				if not input_data.state then 
	--				OffyLib:c_log("Show")
					menu:Show()
				end
			else
				if input_data.state then
	--				OffyLib:c_log("Hide")
					menu:Hide(true)
				end
			end
		end
		
		input_data.state = state
	end
	
end

function QuickChat:GetMenu(index)
	return index and self.radial_menus[index]
end

function QuickChat:ToggleMenu(index)
	local menu = index and self.radial_menus[index]
	if menu then 
		menu:Toggle()
	end
end

function QuickChat:LoadCustomRadials()
	local path = self._save_path
	if self._lip then 
		local radial_items = self._lip.load(path)
		
	end
end

function QuickChat:SendChat(msg)
	if managers.chat then
		local session = managers.network and managers.network:session()
		local peer_id = session:local_peer():id()
		local col = tweak_data.chat_colors[peer_id]
		local username = managers.network.account:username()
		managers.chat:_receive_message(1,username,msg,col)
		managers.chat:send_message(managers.chat._channel_id,username,msg)
	end
end

do --load RadialMenu
	local f,e = blt.vm.loadfile(QuickChat._mod_path .. "req/RadialMenu.lua")
	if f then 
		QuickChat._radial_menu_manager = f()
		log("[QuickChat] RadialMenu loaded successfully.")
	else
		log("[QuickChat] Error loading RadialMenu.lua:")
		log(e)
	end
end
do --load Lua ini Parser
	local f,e = blt.vm.loadfile(QuickChat._mod_path .. "req/QuickChat.lua")
	if f then 
		QuickChat._lip = f()
		log("[QuickChat] LIP loaded successfully.")
	else
		log("[QuickChat] Error loading RadialMenu.lua:")
		log(e)
	end
end

--[[ input button name reference
	--inputs from any given input device (keyboard, xbox360/xb1/ps3/ps4/steam controller) are translated into a VirtualController,
	--which uses generic input names instead of device-specific input names
	
	--below are the generic input names
	
	local buttons = {
		"confirm", -- a
		"cancel", -- b
		"reload", -- x
		"switch_weapon", -- y
		"start", -- start
		"back", -- back
		"weapon_gadget", -- d-pad up
		"push_to_talk", -- d-pad down
		"left", -- d-pad left
		"right", -- d-pad right
		"use_item", -- left bumper
		"interact", -- right bumper
		"trigger_right", -- right trigger
		"trigger_left", -- left trigger
		"run", -- left thumbstick down
		"melee" -- right thumbstick down
	}
	
	--these are for analog inputs, which provide a table containing inputs for the x and y axis
	--d-pad is also provided as an analog axis input as well as digital button input but i don't feel like looking it up rn
	local axis = {
		"move",
		"look"
	}
--]]


Hooks:Add("BaseNetworkSessionOnLoadComplete","QuickChat_OnLoaded",callback(QuickChat,QuickChat,"CreateMenu"))