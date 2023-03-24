--TODO
	--SCHEMA
		--todo use _supported_controller_type_map instead of manual mapping?
			--may not be necessary if only the wrapper type is used
		--todo: in networksession hooks, send only to synced player?
		--make saves/QuickChat/layout/ directory
		--needs third avenue for VR with kb/virtualcontroller

	--FEATURES
		--allow mouse button binding for keyboard users
		--display current gamepad mode in menu
		--customization
			--custom radial messages (use QKI?)
			--preview radial in menu
			--button combos?
		--localize menu button names for controllers, per gamepad type
		--allow selecting button by waiting at menu (for controllers) for x seconds
			--(this allows controllers to bind or reserve any options they desire, without interfering with menu operation)
		
		--PING MENU design notes
			--no text, with the following exceptions:
				--timers
				--auto-generated text (automatically determined ping targets)
			--two variants with separate keybinds
				--temp markers
					--disappears on a timer
				--permanent markers
					--stays until removed
				
			--button/keybind to remove all markers
				--remove all marker data AND all panel children
	
	--BUGS
		--the dreaded input bug is back for keyboards in-game; no input detected in binding menu

QuickChat = QuickChat or {
	_radial_menu_manager = nil, --for reference
	_lip = nil 					--for reference
}
QuickChat._core = QuickChatCore
QuickChat._mod_path = (QuickChatCore and QuickChatCore.GetPath and QuickChatCore:GetPath()) or ModPath
QuickChat._save_path = SavePath .. "QuickChat/"
QuickChat._bindings_name = "bindings_$WRAPPER.json"
QuickChat._controller_bindings_name = "controller_bindings.json"
--vr bindings?
QuickChat._settings_name = "settings.json"
QuickChat.default_settings = {}
QuickChat.settings = {} --general user pref (unused)
QuickChat.sort_settings = {}
QuickChat._bindings = {
--[[
	callouts_1 = "j",
	deployables_1 = "k",
	custom_1 = "l"
--]]
}
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
QuickChat._radial_menus = {} --generated radial menus
QuickChat._radial_menu_params = {} --ungenerated radial menus; populated with user data

QuickChat._callback_bind_button = nil --dynamically set
QuickChat._updaters = {}
	
QuickChat._input_cache = {}

QuickChat.allowed_binding_buttons = { --wrapper-specific bindings
	pc = {
		buttons = { --the index of each these buttons as far as the controller is concerned is generally derived from its position on the keyboard, from left to right, then top to bottom (ie western book-reading order); eg. esc is 1, f1 is 2, f2 is 3, etc.
			--numbers
			"1","2","3","4","5","6","7","8","9","0",
			--letters
			"a","b","c","d","e","f","g","h","j","i","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
			--function key row
			"f1","f2","f3","f4","f5","f6","f7","f8","f9","f10","f11","f12",
			--punctuations and symbols
			"'","\\",",","=","`","[","-",".","]",";","/"," ",
			--arrow keys
			"up","down","left","right",
			--control keys
			"backspace","caps lock","delete","end","enter","esc","home","insert","left alt","left ctrl","left shift","left windows","page down","page up","right alt","right ctrl","right shift","right windows","scroll lock","sys rq","tab",
			--numpad
			"num 0","num 1","num 2","num 3","num 4","num 5","num 6","num 7","num 8","num 9","num lock","num ,","num enter","num =","num +","num .","num /","num -","num *",
			--application and media keys
			"applications","calculator","mail","media select","media stop","mute","my computer","next track","pause","play pause","power","prev track","sleep","volume up","volume down","wake","web back","web favorites","web forward","web home","web refresh","web search","web stop",
			--international keys
			"num abnt c1","num abnt c2","@","ax",":","convert","kana","kanji","no convert","oem 102","stop","_","unlabeled","yen"
		},
		axis = {} --no axes for keyboards; mouse axis input is handled separately
	},
	xbox360 = {
		buttons = {
			["d_up"] = "weapon_gadget",
			["d_down"] = "push_to_talk",
			["d_left"] = "left",
			["d_right"] = "right",
			["start"] = "start",
			["back"] = "back",
			["left_thumb"] = "run",
			["right_thumb"] = "melee",
			["left_shoulder"] = "use_item",
			["right_shoulder"] = "interact",
			["left_trigger"] = "trigger_left",
			["right_trigger"] = "trigger_right",
			["a"] = "confirm",
			["b"] = "cancel",
			["x"] = "reload",
			["y"] = "switch_weapon"
		},
		axis = {
			["left"] = "move",
			["right"] = "look",
			["dpad"] = "dpad" --no idea if this is correct!
		}
	},
	ps3 = {
		buttons = {
			["d_up"] = "weapon_gadget",
			["d_down"] = "push_to_talk",
			["d_left"] = "left",
			["d_right"] = "right",
			["start"] = "start",
			["back"] = "back",
			["left_thumb"] = "run",
			["right_thumb"] = "melee",
			["left_shoulder"] = "use_item",
			["right_shoulder"] = "interact",
			["left_trigger"] = "trigger_left",
			["right_trigger"] = "trigger_right",
			["cross"] = "confirm",
			["circle"] = "cancel",
			["square"] = "reload",
			["triangle"] = "switch_weapon"
		},
		axis = {
			["left"] = "move",
			["right"] = "look",
			["dpad"] = "dpad"
		}
	}
}
QuickChat.allowed_binding_buttons.ps4 = QuickChat.allowed_binding_buttons.ps3
QuickChat.allowed_binding_buttons.xb1 = QuickChat.allowed_binding_buttons.xbox360

QuickChat._allowed_binding_buttons = {}

--load dependencies/classes
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

function QuickChat:Log(msg)
	if Console then
		Console:Log(msg)
	end
end

--Setup

function QuickChat:Setup() --on game setup complete
	self:PopulateInputCache()
	self:AddUpdater("QuickChat_UpdateInGame",callback(self,self,"UpdateGame"),false)
end

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

function QuickChat:ClearInputCache()
	for button_name_ids,input_data in pairs(self._input_cache) do 
		local menu = self:GetMenu(input_data.id)
		if menu then 
			menu:Hide(false) --do not activate "confirm" callback
		end
		self._input_cache[button_name_ids] = nil
	end
end

function QuickChat:PopulateInputCache()--for each radial menu that is bound to a button, create a menu if it does not already exist
	--then register it in the input cache so that the button state can be checked each frame
	local binding_data = self._bindings
	if binding_data then
		for radial_id,button_name in pairs(binding_data) do
			local button_name_ids = Idstring(button_name)
			self._input_cache[button_name_ids] = {id = radial_id,state = false,button_name = button_name}
			if not self._radial_menus[radial_id] then
				local radial_menu_params = self._radial_menu_params[radial_id]
				if radial_menu_params then
					local new_menu = self._radial_menu_manager:NewMenu(radial_menu_params)
					self._radial_menus[radial_id] = new_menu
				else
					self:Log("Error creating menu: " .. tostring(radial_id))
				end
			end
		end
	end
end

--Keybind and Input Management

function QuickChat:GetRadialIdByKeybind(keyname)
	for radial_id,_keyname in pairs(self._bindings) do 
		if _keyname == keyname then
			return radial_id
		end
	end
end

function QuickChat:GetKeybindByRadialId(radial_id)
	return radial_id and self._bindings[radial_id]
end

function QuickChat:IsGamepadModeEnabled()
	return managers.controller and managers.controller:get_default_wrapper_type() ~= "pc"
end

function QuickChat:UnpackGamepadBindings()
	local wrapper_type = managers.controller:get_default_wrapper_type()
	local allowed_wrapper_bindings = self.allowed_binding_buttons[wrapper_type]
	if allowed_wrapper_bindings then 
		local allowed_wrapper_buttons = allowed_wrapper_bindings.buttons
		for controllerbutton,wrapperbutton in pairs(allowed_wrapper_buttons) do
			QuickChat._allowed_binding_buttons[Idstring(controllerbutton):key()] = controllerbutton
		end
--		if wrapper_type == "pc" then 
			--todo load mouse buttons here
--		end
	end
end

function QuickChat:GetController()
	local controller
	if self:IsGamepadModeEnabled() then 
		local cm = managers.controller
		local index = Global.controller_manager.default_wrapper_index or cm:get_preferred_default_wrapper_index()
		
		local controller_index = cm._wrapper_to_controller_list[index][1]
		controller = Input:controller(controller_index)
		--[[
		local player_unit = managers.player and managers.player:local_player()
		local wrapper = managers.system_menu:_get_controller()
		if alive(player_unit) then 
			local state = player_unit:movement():current_state()
			wrapper = state._controller or wrapper
		end
		local wrapper_index = wrapper and wrapper._id
--		local controller_index = wrapper_index and managers.controller._wrapper_to_controller_list[wrapper_index]
		controller = wrapper_index and Input:controller(wrapper_index)
		--]]
	else
		controller = Input:keyboard()
	end
	return controller
end

--Radial Menu Management

function QuickChat:LoadMenuFromIni(ini_data) --converts and validates saved data from ini format into a table ready to be passed to the radial menu constructor
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

function QuickChat:GetMenu(id)
	return id and self._radial_menus[id]
end

function QuickChat:ToggleMenu(id)
	local menu = id and self._radial_menus[id]
	if menu then 
		menu:Toggle()
	end
end

--Networking

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
				local local_peer = session:local_peer()
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
				managers.chat:receive_message_by_peer(ChatManager.GAME,local_peer,text_localized)
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
		managers.chat:send_message(ChatManager.GAME,username,msg)
	end
end

function QuickChat:SendSyncPeerVersionToAll()
	LuaNetworking:SendToPeers(self.SYNC_MESSAGE_REGISTER,self.API_VERSION)
end

--Updaters

function QuickChat:AddControllerInputListener()
	self:AddUpdater("quickchat_update_rebinding",callback(self,self,"UpdateRebindingListener"),true)
end

function QuickChat:RemoveControllerInputListener()
	self:RemoveUpdater("quickchat_update_rebinding")
end

function QuickChat:UpdateRebindingListener(t,dt)
	--options: --pressed_list --released_list --down_list 
	local controller = self:GetController()
	if controller then
		local pressed_list = controller:pressed_list()
		local gamepad_mode_enabled = self:IsGamepadModeEnabled()
		if #pressed_list > 0 then
			for _,button_index in ipairs(pressed_list) do 
				local button_ids = controller:button_name(button_index)
				local button_ids_key = button_ids:key()
				
				if self._allowed_binding_buttons[button_ids_key] then
--						self:Log("detected controller " .. button_name)
--						if gamepad_mode_enabled then 
--						end
					local button_name = self._allowed_binding_buttons[button_ids_key]
					--associate that menu with this button
					if self._callback_bind_button then
						self:_callback_bind_button(button_name)
					end
					self:RemoveControllerInputListener()
					break
				end
			end
		end
	end
	
	if not gamepad_mode_enabled then
--		local mouse = Input:mouse()
		
		--check mouse input (different controller)
	end
end

function QuickChat:AddUpdater(id,func,run_while_paused)
	local f_type = type(func)
	if f_type == "function" then
		self._updaters[id] = {
			id = id,
			func = func,
			pause_enabled = run_while_paused
		}
	else
		self:Log("ERROR: Bad updater type for " .. tostring(id) .. ": " .. f_type .. " (expected function)")
	end
end

function QuickChat:RemoveUpdater(id)
	self._updaters[id] = nil
end

function QuickChat:Update(source,t,dt)
	local game_is_paused = source == "GameSetupPausedUpdate"
	--todo split into separate updater table for efficiency
	for id,data in pairs(self._updaters) do 
		if not game_is_paused or data.pause_enabled then
			data.func(t,dt,game_is_paused)
		end
	end
end

function QuickChat:UpdateGame(t,dt)
	local controller = self:GetController()
	if not controller then
		return
	end
	for button_name_ids,input_data in pairs(self._input_cache) do 
		
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
					if self:IsGamepadModeEnabled() then 
						local player_unit = managers.player:local_player()
						if alive(player_unit) then
							local camera = player_unit:camera()
							local fpcamera_unit = camera and camera._camera_unit
							local fpcamera_base = fpcamera_unit and fpcamera_unit:base()
							if fpcamera_base then
								fpcamera_base._last_rot_t = nil
							end
						end
						
					end
					menu:Hide(true)
				end
			end
		end
		
		input_data.state = state
	end
end

--I/O

function QuickChat:GetBindingsFileName()
	return string.gsub(self._bindings_name,"$WRAPPER",managers.controller:get_default_wrapper_type())
end

function QuickChat:LoadSettings()
	self:LoadBindings(self:GetBindingsFileName())
end

function QuickChat:SaveSettings()
	self:SaveBindings(self:GetBindingsFileName())
end

function QuickChat:SaveBindings(filename)
	local save_path = self._save_path .. tostring(filename)
	local file = io.open(save_path,"w+")
	if file then
		file:write(json.encode(self._bindings))
		file:close()
	end
end

function QuickChat:LoadBindings(filename)
	local save_path = self._save_path .. tostring(filename)
	local file = io.open(save_path, "r")
	if file then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self._bindings[k] = v
		end
	end
end

Hooks:Add("MenuManagerSetupCustomMenus","QuickChat_MenuManagerSetupCustomMenus",function(menu_manager, nodes)
	QuickChat:UnpackGamepadBindings()
	QuickChat:LoadSettings()
	QuickChat:LoadCustomRadials()
	
	MenuHelper:NewMenu("quickchat_menu_main")
end)

Hooks:Add("MenuManagerPopulateCustomMenus","QuickChat_MenuManagerPopulateCustomMenus",function(menu_manager, nodes)
	local quickchat_main_menu_id = "quickchat_menu_main"
	local unbound_text = managers.localization:text("qc_bind_status_unbound")
	
	--create menus for each user radial, in alphabetical order
	local radial_keys = {}
	for radial_id,radial_data in pairs(QuickChat._radial_menu_params) do 
		table.insert(radial_keys,radial_id)
	end
	table.sort(radial_keys)
	local num_keys = #radial_keys
	local num_options = 3
	
	local num_items = num_keys * num_options
	
	local function refresh_menu_item(menu_id,index,new_text)
		local parent_menu = MenuHelper:GetMenu(menu_id)
		local item = parent_menu._items_list[1 + (num_items - index)]
		if item then 
			item._parameters.text_id = new_text
			item._parameters.gui_node:_reload_item(item)
		end
	end
	
	for i,radial_id in ipairs(radial_keys) do 
		local current_binding_text = unbound_text
		local current_button = QuickChat:GetKeybindByRadialId(radial_id)
		if current_button then
			current_binding_text = managers.localization:text("qc_bind_status_title",{KEYNAME=utf8.to_upper(current_button)})
		end
--		local menu_id = string.format("quickchat_radial_menu_%i",i)
--		local new_menu = MenuHelper:NewMenu(menu_id)
		local j = i - 1
		local radial_data = QuickChat._radial_menu_params[radial_id]
		
		local header_id = string.format("quickchat_radial_header_%i",i)
		local item_id = string.format("quickchat_radial_button_%i",i)
		local divider_id = string.format("quickchat_radial_divider_%i",i)
		local callback_id = string.format("quickchat_radial_binding_%i",i)
		local header_priority = num_items - (j * num_options)
		local item_priority = header_priority - 1
		local divider_priority = header_priority - 2
		MenuHelper:AddButton({
			id = header_id,
			title = radial_id,
			desc = "",
			localized = false,
			callback = nil,
			menu_id = quickchat_main_menu_id,
			disabled = true,
			priority = header_priority
		})
		MenuHelper:AddButton({
			id = item_id,
			title = current_binding_text,
			desc = managers.localization:text("qc_bind_status_desc"),
			localized = false,
			callback = callback_id,
			menu_id = quickchat_main_menu_id,
			disabled = false,
			priority = item_priority
		})
		MenuHelper:AddDivider({
			id = divider_id,
			size = 16,
			menu_id = quickchat_main_menu_id,
			priority = divider_priority
		})
		MenuCallbackHandler[callback_id] = function(self)
			local title,desc
			local button_unbind_name,button_cancel_name
			if QuickChat:IsGamepadModeEnabled() then
				title = "qc_menu_bind_prompt_controller_title"
				desc = "qc_menu_bind_prompt_controller_desc"
				button_unbind_name = "start"
				button_cancel_name = "back"
			else
				title = "qc_menu_bind_prompt_keyboard_title"
				desc = "qc_menu_bind_prompt_keyboard_desc"
				button_unbind_name = "backspace"
				button_cancel_name = "esc"
			end
			QuickChat._quickmenu_item = QuickMenu:new(
				managers.localization:text(title),
				managers.localization:text(desc,{BTN_UNBIND=utf8.to_upper(button_unbind_name),BTN_CANCEL=utf8.to_upper(button_cancel_name)}),
				{
					{
						text = managers.localization:text("qc_menu_bind_prompt_unbind"),
						callback = function()
							if QuickChat._callback_bind_button then
								QuickChat:_callback_bind_button(button_unbind_name)
							end
							QuickChat:RemoveControllerInputListener()
						end
					},
					{
						text = managers.localization:text("qc_menu_dialog_cancel"),
						is_cancel_button = true,
						is_default_button = true,
						callback = function()
							QuickChat:RemoveControllerInputListener()
						end
					}
				},
				true
			)
			
			--called on pressing a button in the bind dialog
			QuickChat._callback_bind_button = function(self,button_name)
				if self._quickmenu_item then 
					self._quickmenu_item:Hide()
					self._quickmenu_item = nil
				end
				if button_name == button_unbind_name then 
					--unbind and close
					local _button_name = self._bindings[radial_id]
					if _button_name then
						QuickMenu:new(
							managers.localization:text("qc_menu_bind_prompt_unbound_title"),
							managers.localization:text("qc_menu_bind_prompt_unbound_desc",{KEYNAME=utf8.to_upper(_button_name),RADIAL=radial_id}),
							{
								{
									text = managers.localization:text("qc_menu_dialog_accept"),
									is_cancel_button = true
								}
							},
							true
						)
					end
					self._bindings[radial_id] = nil
					refresh_menu_item(quickchat_main_menu_id,item_priority,unbound_text)
				elseif button_name == button_cancel_name then
					--cancel, do nothing
					return
				else
					
					--internal keybind conflict detection
					for _radial_id,_button_name in pairs(self._bindings) do 
						if (_button_name == button_name) and (_radial_id ~= radial_id) then 
							QuickMenu:new(
								managers.localization:text("qc_menu_bind_prompt_conflict_title"),
								managers.localization:text("qc_menu_bind_prompt_conflict_desc",{KEYNAME=utf8.to_upper(_button_name),RADIAL=_radial_id}),
								{
									{
										text = managers.localization:text("qc_menu_dialog_accept"),
										is_cancel_button = true
									}
								},
								true
							)
							return
						end
					end
					
					self._bindings[radial_id] = button_name
					QuickMenu:new(
						managers.localization:text("qc_bind_status_success_title"),
						managers.localization:text("qc_bind_status_success_desc",{KEYNAME=utf8.to_upper(button_name),RADIAL=radial_id}),
						{
							{
								text = managers.localization:text("qc_menu_dialog_accept"),
								is_cancel_button = true
							},
						},
						true
					)
					self:ClearInputCache()
					self:PopulateInputCache()
					refresh_menu_item(quickchat_main_menu_id,item_priority,managers.localization:text("qc_bind_status_title",{KEYNAME=utf8.to_upper(button_name)}))
				end
				
				self:SaveSettings()
				self._callback_bind_button = nil
			end
			
			QuickChat:AddControllerInputListener()
		end
	end
end)

Hooks:Add("MenuManagerBuildCustomMenus","QuickChat_MenuManagerBuildCustomMenus",function(menu_manager, nodes)
		nodes.quickchat_menu_main = MenuHelper:BuildMenu(
		"quickchat_menu_main",{
			area_bg = "none",
			back_callback = "callback_menu_quickchat_back",
			focus_changed_callback = nil
		}
	)
	MenuHelper:AddMenuItem(nodes.blt_options,"quickchat_menu_main","qc_menu_main_title","qc_menu_main_desc")
	
end)

Hooks:Add("MenuManagerInitialize","QuickChat_MenuManagerInitialize",function(menu_manager)
	MenuCallbackHandler.callback_menu_quickchat_back = function()
		QuickChat:ClearInputCache()
		QuickChat:PopulateInputCache()
	end
--	QuickChat:Setup()
end) 

Hooks:Register("QuickChat_LoadCustomRadials")
Hooks:Add("QuickChat_LoadCustomRadials","QuickChat_OnLoadCustomRadials",function(data) --not fully implemented
	local radial_id,new_radial_data = self:LoadMenuFromIni(data)
	if new_radial_data then
		self._radial_menu_params[radial_id] = new_radial_data
	end
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

Hooks:Add("BaseNetworkSessionOnLoadComplete","QuickChat_OnLoaded",callback(QuickChat,QuickChat,"Setup"))

Hooks:Add("GameSetupUpdate","QuickChat_GameUpdate",callback(QuickChat,QuickChat,"Update","GameSetupUpdate"))
Hooks:Add("GameSetupPausedUpdate","QuickChat_GamePausedUpdate",callback(QuickChat,QuickChat,"Update","GameSetupPausedUpdate"))
Hooks:Add("MenuUpdate","QuickChat_MenuUpdate",callback(QuickChat,QuickChat,"Update","MenuUpdate"))

--[[
--input button name reference
--sorted by US standard keyboard layout
QuickChat._buttons_list = {
	--inputs from any given input device (keyboard, xbox360/xb1/ps3/ps4/steam controller) are translated into a VirtualController,
	--which uses generic input names instead of device-specific input names
	keyboard = {
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
	},
	virtualcontroller = {
		--below are the generic input names
		buttons = {
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
		},
		axis = {
			--these are for analog inputs, which provide a table containing inputs for the x and y axis
			--d-pad is also provided as an analog axis input as well as digital button input but i don't feel like looking it up rn
			"move",
			"look"
		}
	},
	
	
}
--]]