--todo: in networksession hooks, send only to synced player?
--input check in update should save a flag for is_controller, and check Input:mouse() for pc input
--default data
--sometimes virtualcontroller input checking just breaks for no reason!
--make saves/QuickChat/layout/ directory

QuickChat = QuickChat or {
	_radial_menu_manager = nil, --for reference
	_lip = nil 					--for reference
}
QuickChat._core = QuickChatCore
QuickChat._mod_path = (QuickChatCore and QuickChatCore.GetPath and QuickChatCore:GetPath()) or ModPath
QuickChat._save_path = SavePath .. "QuickChat/"
QuickChat._settings_name = "settings.json"
QuickChat.settings = {
	pc = {
		j = "callouts_1"
	},
	controller_generic = {
		left = "callouts_1"
	}
} --general user pref
QuickChat.sort_settings = {}

QuickChat.SYNC_MESSAGE_PRESET = "QuickChat_message_preset"
QuickChat.SYNC_MESSAGE_REGISTER = "QuickChat_Register"
QuickChat.API_VERSION = "1" -- string!

QuickChat._message_presets = {
	yes = "qc_ptm_yes",
	no = "qc_ptm_no",
	greeting = "qc_ptm_greeting",
	thanks = "qc_ptm_thanks",
	apology = "qc_ptm_apology",
	help = "qc_ptm_help",
	attack = "qc_ptm_attack",
	defend = "qc_ptm_defend",
	need_docbag = "qc_ptm_need_docbag",
	need_fak = "qc_ptm_need_fak",
	need_ammo = "qc_ptm_need_ammo",
	need_ecm = "qc_ptm_need_ecm",
	need_sentrygun = "qc_ptm_need_sentrygun",
	need_tripmine = "qc_ptm_need_tripmine",
	need_shapedcharge = "qc_ptm_need_shapedcharge",
	need_grenades = "qc_ptm_need_grenades",
	need_convert = "qc_ptm_need_convert"
}

QuickChat._preset_callbacks = {
	chat = function(item_data)
		return function()
			if item_data.preset_text then 
				QuickChat:SendPresetMessage(item_data.preset_text)
			elseif item_data.text then
				QuickChat:SendChatToAll(item_data.text)
			end
		end
	end
}
QuickChat.radial_menus = {} --generated radial menus
QuickChat._radial_menu_params = {} --ungenerated radial menus; populated with user data

QuickChat.input_cache = {}
QuickChat.bindings = {
	mousekeyboard = {
		["j"] = "callouts_1",
		["k"] = "deployables_1",
		["l"] = "custom_1"
	},
	virtualcontroller = {
		["left"] = "callouts_1",
		["right"] = "deployables_1",
		["push_to_talk"] = "custom_1"
	}
	--[[
	pc = {
		["j"] = "callouts_1"
	},
	--platform specific bindings
	,ps3 = {},
	ps4 = {},
	xb1 = {},
	xbox360 = {
		["left"] = "callouts_1"
	},
	gamepad = {},
	vr = {},
	steam = {}
	--]]
}

function QuickChat:LoadCustomRadials()
	if self._lip then
		local directory_exists = file.DirectoryExists
		local file_exists = file.FileExists
		local function get_files(path)
			if SystemFS and SystemFS.list then 
				return SystemFS:list(path)
			else
				return file.GetFiles(path)
			end
		end
		local function make_dir(path)
			if SystemFS and SystemFS.make_dir then
				local p
				for _, s in pairs(string.split(path, "/")) do
					p = p and p .. "/" .. s  or s
					if not directory_exists(p) then
						SystemFS:make_dir(p)
					end
				end
			else
				os.execute(string.format("mkdir \"%s\"", path))
			end
		end
		
		--load default layouts (built-in) first
		local layout_path = self._mod_path .. "layouts/"
		local files = get_files(layout_path)
		for _,filename in pairs(files) do 
			local ext = string.sub(filename,-4)
			if ext == ".ini" then
				--check if get_files is alphabetized
				local ini_data = self._lip.load(layout_path .. filename)
				local radial_id,new_radial_data = self:LoadMenuFromIni(ini_data)
				if new_radial_data then
					radial_id = radial_id or string.sub(filename,1,-5)
					self._radial_menu_params[radial_id] = new_radial_data
				end
			end
		end
		
		--load custom layouts last so that they can overwrite existing defaults
		local save_path = self._save_path
		if not directory_exists(save_path) then 
			make_dir(save_path)
		end
		if directory_exists(save_path) then
			local files = get_files(save_path)
			for _,filename in pairs(files) do 
				local ext = string.sub(filename,-4)
				if ext == ".ini" then
					--check if get_files is alphabetized
					local ini_data = self._lip.load(save_path .. filename)
					local radial_id,new_radial_data = self:LoadMenuFromIni(ini_data)
					if new_radial_data then
						radial_id = radial_id or string.sub(filename,1,-5)
						self._radial_menu_params[radial_id] = new_radial_data
					end
				end
			end
		else
			--unable to make dir
		end
		
	end
end

function QuickChat:LoadMenuFromIni(ini_data)
	if ini_data then
		local new_menu_params = {
			items = {}
		}
		
		local basic_body_values = {
			"id",
			"size",
			"deadzone",
			"focus_alpha",
			"unfocus_alpha",
			"item_margin",
			"item_text_visible"
		}
		local basic_item_values = {
			"keep_open",
			"font",
			"font_size"
		}
		
		
		local body = ini_data.RadialMenu
		local id = body.id
		local default_menu_data = {} --self._radial_menu_params.default
		
		if body then
			
			for _,key in pairs(basic_body_values) do 
				if body[key] ~= nil then 
					new_menu_params[key] = body[key]
				end
			end
			
			new_menu_params.texture_highlight = body.texture_highlight or default_menu_data.texture_highlight
			new_menu_params.texture_darklight = body.texture_darklight or default_menu_data.texture_darklight
			new_menu_params.texture_cursor = body.texture_cursor or default_menu_data.texture_cursor
			
			for i,item_data in ipairs(ini_data) do 
				local new_item = {}
				if item_data.icon_id then
					local texture,texture_rect = tweak_data.hud_icons:get_icon_data(item_data.icon_id)
					new_item.texture = texture
					new_item.texture_rect = texture_rect
				elseif item_data.texture then
					new_item.texture = item_data.texture
					if item_data.texture_rect then 
						new_item.texture_rect = string.split(item_data.texture_rect,",")
					end
				end
				
				
				if item_data.preset_text and self._message_presets[item_data.preset_text] then 
					new_item.preset_text = item_data.preset_text
					new_item.text = managers.localization:text(self._message_presets[item_data.preset_text])
				elseif item_data.text then 
					new_item.text = item_data.text
				end
				if item_data.preview_text then --not localized
					new_item.text = item_data.preview_text
				end
				
				if item_data.color then 
					local color
					if string.find(item_data.color,",") then
						local col_tbl = string.split(item_data.color,",")
						color = Color(unpack(col_tbl))
					else
						color = Color(item_data.color)
					end
					if color then 
						new_item.color = color
					end
				end
				
				if item_data.custom_callback then 
					local f,e = loadstring(custom_callback)
					if f then 
						new_item.callback = f
					else
						--error
	--					log(e)
					end
				elseif item_data.preset_callback then 
					local f = self._preset_callbacks[item_data.preset_callback]
					new_item.callback = f and f(item_data)
				end
				
				for _,key in pairs(basic_item_values) do 
					if item_data[key] ~= nil then 
						new_item[key] = item_data[key]
					end
				end
				
				new_menu_params.items[i] = new_item
			end
			
		end
		return id,new_menu_params
	end
end

function QuickChat:CreateMenus()
	local wrapper_type = managers.controller:get_default_wrapper_type()
	self._gamepad_mode_enabled = wrapper_type ~= "pc"
	
	local control_type
	if self._gamepad_mode_enabled then 
		control_type = "virtualcontroller"
	else
		control_type = "mousekeyboard"
	end
	--only create menu objects for radial menus that are bound to at least one key
	local binding_data = self.bindings[control_type]
	if binding_data then
		for button_name,radial_id in pairs(binding_data) do
			local button_name_ids = Idstring(button_name)
			self.input_cache[button_name_ids] = {id = radial_id,state = false}
			if not self.radial_menus[radial_id] then
				local radial_menu_params = self._radial_menu_params[radial_id]
				local new_menu = self._radial_menu_manager:NewMenu(radial_menu_params)
				self.radial_menus[radial_id] = new_menu
			end
		end
	end
	BeardLib:AddUpdater("quickchat_update_keyboard_input",callback(self,self,"Update"))
end

function QuickChat:Update(t,dt)
	local player_unit,player_alive
	if self._gamepad_mode_enabled then 
		player_unit = managers.player and managers.player:local_player()
		player_alive = player_unit and alive(player_unit)
		if player_alive then 
			local state = player_unit:movement():current_state()
			local _controller = state._controller or managers.system_menu:_get_controller()
			local ci = _controller._id
			controller = Input:controller(ci)
		end
	else
		controller = Input:keyboard()
	end
	
	if not controller then return end
	
	
	for button_name_ids,input_data in pairs(self.input_cache) do 
		
		local menu = self:GetMenu(input_data.id)
		local state = controller:down(button_name_ids)
--		_G.Console:SetTracker(string.format("Key down %s,%.1f,",state,t),1)
		if menu then
			if state then 
				if not input_data.state then --and not any_open
--					_G.Console:SetTracker("is active? " .. tostring(self._last_menu and self._last_menu:IsActive()),2)
					if not (self._last_menu and self._last_menu:IsActive()) then
--						_G.Console:SetTracker(string.format("show %.1f",t),3)
						menu:Show()
						self._last_menu = menu
					end
				end
			else
				if input_data.state then
--					_G.Console:SetTracker(string.format("hide %.1f",t),4)
					if self._gamepad_mode_enabled and player_alive then 
						local camera = player_unit:camera()
						local fpcamera_unit = camera and camera._camera_unit
						local fpcamera_base = fpcamera_unit and fpcamera_unit:base()
						if fpcamera_base then
							fpcamera_base._last_rot_t = nil
						end
						
					end
					menu:Hide(true)
				end
			end
		end
		
		input_data.state = state
	end
	
end

function QuickChat:GetMenu(id)
	return id and self.radial_menus[id]
end

function QuickChat:ToggleMenu(id)
	local menu = id and self.radial_menus[id]
	if menu then 
		menu:Toggle()
	end
end

function QuickChat:RegisterPeerById(peer_id,version)
	if peer_id then 
		local session = managers.network:session()
		local peer = session and session:peer(peer_id)
		if peer then 
			peer._quickchat_version = version
		end
	end
end

function QuickChat:GetPeerVersion(peer_id)
	if peer then 
		return peer._quickchat_version
	end
end

function QuickChat:SendPresetMessage(preset_text)
	if managers.chat then
		local network_mgr = managers.network
		if network_mgr then
			local session = network_mgr:session()
			if session then 
				local local_peer_id = session:local_peer():id()
				local local_peer_color = tweak_data.chat_colors[local_peer_id]
				local username = network_mgr.account:username()
				local text_localized = managers.localization:text(self._message_presets[preset_text])
				for _,peer in pairs(session:peers()) do 
					local quickchat_version = peer._quickchat_version 
					if quickchat_version then
						--if the QC API changes in the future, outbound messages will be reformatted here
						LuaNetworking:SendToPeer(peer:id(),self.SYNC_MESSAGE_PRESET,preset_text)
					else
						if peer:ip_verified() then
							peer:send("send_chat_message", ChatManager.GAME, text_localized) --LuaNetworking.HiddenChannel
						end
					end
				end
				managers.chat:_receive_message(ChatManager.GAME,username,text_localized,local_peer_color)
			end
		end
	end
end

function QuickChat:ReceivePresetMessage(peer_id,preset_text)
	if managers.chat then
		local network_mgr = managers.network
		if network_mgr then
			local session = network_mgr:session()
			if session then
				local peer = session:peer()
				if peer then
					local peer_color = tweak_data.chat_colors[peer_id]
					local username = peer:name()
					local text_localized = preset_text and managers.localization:text(self._message_presets[preset_text])
					--local quickchat_version = peer._quickchat_version
					--if the QC API changes in the future, inbound messages will be reformatted here
					managers.chat:_receive_message(ChatManager.GAME,username,text_localized,peer_color)
				end
			end
		end
	end
end

function QuickChat:SendChatToAll(msg)
	if managers.chat then
		local session = managers.network:session()
		local peer_id = session:local_peer():id()
		local col = tweak_data.chat_colors[peer_id]
		local username = managers.network.account:username()
--		managers.chat:_receive_message(ChatManager.GAME,username,msg,col)
		managers.chat:send_message(ChatManager.GAME,username,msg)
	end
end

function QuickChat:SendSyncPeerVersionToAll()
	LuaNetworking:SendToPeers(self.SYNC_MESSAGE_REGISTER,self.API_VERSION)
end

function QuickChat:LoadSettings()
	if self._lip then 
		--[[
		local save_file_name = self._save_path .. self._settings_name
		if file.FileExists(save_file_name) then
			local save_data = self._lip.load(save_file_name)
			local settings_data = save_data.Settings
			local bindings_data = save_data.Bindings
		end
		--]]
	end
end

function QuickChat:SaveSettings()
	
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
	local f,e = blt.vm.loadfile(QuickChat._mod_path .. "req/LIP.lua")
	if f then 
		QuickChat._lip = f()
		log("[QuickChat] LIP loaded successfully.")
	else
		log("[QuickChat] Error loading LIP.lua:")
		log(e)
	end
end

Hooks:Add("MenuManagerSetupCustomMenus","QuickChat_MenuManagerSetupCustomMenus",function(menu_manager, nodes)
	
end)
Hooks:Add("MenuManagerPopulateCustomMenus","QuickChat_MenuManagerPopulateCustomMenus",function(menu_manager, nodes)
	
end)
Hooks:Add("MenuManagerBuildCustomMenus","QuickChat_MenuManagerBuildCustomMenus",function(menu_manager, nodes)
	
end)
Hooks:Add("MenuManagerInitialize","QuickChat_MenuManagerInitialize",function(menu_manager)
	QuickChat:LoadSettings()
	
	QuickChat:LoadCustomRadials()
	QuickChat:CreateMenus()
end)

Hooks:Add("LocalizationManagerPostInit","QuickChat_LocalizationManagerPostInit",function(loc)
	if not BeardLib then 
		loc:load_localization_file(QuickChat._mod_path .. "loc/english.json")
	end
end)

Hooks:Add("NetworkReceivedData","QuickChat_NetworkReceivedData",function(sender, message_id, message_body)
	if message_id == QuickChat.SYNC_MESSAGE_PRESET then
		QuickChat:ReceivePresetMessage(sender,message_body)
	elseif message_id == QuickChat.API_VERSION then
		QuickChat:RegisterPeerById(sender,message_body)
	end
end)



--Hooks:Add("BaseNetworkSessionOnLoadComplete","QuickChat_OnLoaded",callback(QuickChat,QuickChat,"CreateMenus"))


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
