--[[ i have started, stopped, made working prototypes for, scrapped, and restarted this mod no less than 7 times at various points in my time modding this game

todo: 
	conceptually resolve desync issue
	refactor "waypoints", the table that holds processed tweakdata for potential waypoints

--closed captions compatibility?
--create spotlight over target
--hold button to switch to n-second timer?
--timer icon should be separate from normal icon
--edit action radials
--add and custom keybind N number of action radials in menu?
--save current waypoints to table sorted by id64? would be better for saving waypoints if a player disconnects
--re-check peerid on peer list changed
--requires radial mouse menu
--send data through luanetworking
--do not receive data from blocked/muted peers
--don't bother filtering naughty words. anyone who wanted to cuss or toss epithets around could just use chat anyhow
--menu to manually clear waypoints from any or all player(s)

--radial menus can have the following attributes:
	- voiceline to play
	- text (custom; character limit)
	- text (whitelisted)
	- icon id, from hudiconstweakdata
	- countdown timer: game time at which to play the waypoint
	- duration: number of seconds after which this waypoint disappears. leave 0 for non-expiring waypoint

-- opt-in message has the following attributes:
	Integer [mod version]

--networked data can represent the following attributes:
	1 Integer [whitelisted text message id]
	2 String [custom text (optional)]
	3 Integer [icon source type]
	4 String [icon id]
	5 Integer [duration] (rounded up)
	6 Integer [target type]
	7 Integer [target id]
	8 String [encoded position vector3]
--	9 String [encoded normal vector3]?
	9 Integer [owner-authoritative waypoint id for remote destroy]
--]]
--wp_escort

	-- Init mod values --
QuickChat = QuickChat or {}
QuickChat._mod_path = ModQuickChat and ModQuickChat.GetPath and ModQuickChat:GetPath() or ModPath
QuickChat._assets_path = QuickChat._mod_path .. "assets/"
QuickChat._save_path = SavePath .. "quickchat_settings.json"
QuickChat._waypoints_save_path = SavePath .. "quickchat_waypoints.json"
QuickChat._network_data = {
	sync_functions_by_name = { --parsers by version id
		["QuickChat_v1_Register"] = "Register_v1",
		["QuickChat_v1_Add"] = "SyncWaypoint_v1",
		["QuickChat_v1_Remove"] = "SyncRemoveWaypoint_v1"
	},
	sync_functions_by_version = {
		["1"] = {
			add = "QuickChat_v1_Add",
			remove = "QuickChat_v1_Remove",
			register = "QuickChat_v1_Register"
		}
	}
}

QuickChat.default_settings = {
	max_pings_per_player = 2,
	waypoint_fadeout_duration = 1
}
QuickChat.settings = table.deep_map_copy(QuickChat.default_settings)

QuickChat.radial_menu_object_template = {
	name = "PingMenu",
	radius = 200,
	deadzone = 50,
	items = {},
	allow_camera_look = false,
	block_all_input = false,
	allow_keyboard_input = true
}
QuickChat.radial_menu_item_template = {
	text = "Foo Bar!",
	icon = {
		texture = tweak_data.hud_icons.wp_standard.texture,
		texture_rect = tweak_data.hud_icons.wp_standard.texture_rect,
		layer = 3,
		w = 16,
		h = 16,
		alpha = 0.7,
		color = Color.red
	},
--	callback = function() end, --callback(QuickChat,QuickChat,"create_ping","Ping_LookieHere"),
	show_text = false,
	stay_open = false
}
--QuickChat.radial_menu_data = {} --for reference

QuickChat.tweak_data = {
	current_network_message = "QuickChat_v1_Add",
	network_operation_ids = {
		REGISTER = 1,
		ADD = 2,
		REMOVE = 3
	},
	default_waypoints = {
		generic = {
			id = "generic",
			text_id = "text_look",
			color = Color(0,1,1),
			icon_id = "wp_standard",
			effect = "default",
			contextual = true,
			show_distance = true,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = true,
				interactable = true,
				deployables = true
			}
		},
		attack = {
			id = "attack",
			color = Color(1,0.2,0),
			text_id = "text_attack",
			icon_id = "pd2_kill",
			effect = "default",
			show_distance = true,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = false, --not sure
				interactable = true,
				deployables = false
			}
		},
		pickup = {
			id = "pickup",
			color = Color(1,0.2,0),
			text_id = "text_pickup",
			icon_id = "icon_pickup",
			icon_type = 2, --1 = hudiconstweakdata, 2 = premade
			texture = "guis/textures/hud_icons",
			texture_rect = {
				0,
				192,
				45,
				50
			},
			effect = "default",
			show_distance = true,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = false, --not sure
				interactable = true,
				deployables = false
			}
		}
	},
	max_raycast_distance = 10000, --100 meters
	premade_text_messages = {
		text_pickup = "menu_pickup", --get this thing!
		text_interact = "menu_interact", --use this thing!
		text_attack = "menu_attack", --attack this thing!
		text_look = "menu_look" --look at this thing!
	},
	premade_icons = {
		icon_pickup = {
			texture = "guis/textures/hud_icons",
			texture_rect = {
				0,
				192,
				45,
				50
			},
		}
	},
	cast_slotmasks = {
		enemies = {"enemies",26},
		civilians = "civilians",
		friendlies = "criminals",
		interactable = "interactable",
		deployables = "deployables",
		generic = "bullet_targets"
	},
	effects = {
		--not implemented
		default = {
			effect = "effects/particles/weapons/flashlight/fp_flashlight_multicolor", 
			parent_object_name = "Head"
		}
	}
}

--tracker for the number of unique waypoints that a player has created;
--servers as an id to sync to other players when a destroy is requested
QuickChat.num_waypoints = 0

--the custom waypoints for the user (not yet implemented)
QuickChat.user_waypoints = {
--[[

--]]
}

--all waypoints (combined user_waypoints and default_waypoints), processed
QuickChat.waypoints = {

}

QuickChat.registered_peers = {
	--[[
		[id64] = {
			version_id = "1"
		},
	--]]
}
QuickChat.active_waypoints = {} --the waypoints placed by someone in the current game

QuickChat.cast_slotmasks = {} --populated on load

QuickChat.active_radial_menus = {}


	-- General functions --

function QuickChat:log(...)
	if _G.Log then 
		return _G.Log(...)
	end
	return log(...)
end

function QuickChat:OnLoad()
	self._gui = self._gui or World:newgui()
	local td = self.tweak_data

		--populate cast slotmasks
	for k,v in pairs(self.tweak_data.cast_slotmasks) do 
		if type(v) == "string" then
			self.cast_slotmasks[k] = managers.slot:get_mask(v)
		elseif type(v) == "table" then 
			local slotmask = self.cast_slotmasks[v]
			for i,j in pairs(v) do 
				local new_mask
				if type(j) == "string" then 
					new_mask = managers.slot:get_mask(j)
				elseif type (j) == "number" then 
					new_mask = World:make_slot_mask(j)
				end
				if slotmask then 
					slotmask = slotmask + new_mask
				else
					slotmask = new_mask
				end
			end
			self.cast_slotmasks[k] = slotmask
		end
	end
			--process all waypoint data into one usable table on game load, including localized strings
	for k,v in pairs(td.default_waypoints) do 
		local texture,texture_rect 
		if v.texture then 
			texture = v.texture
			texture_rect = v.texture_rect
		elseif v.icon_id then 
			texture,texture_rect = tweak_data.hud_icons:get_icon_data(v.icon_id)
		end
		local slotmask
		for i,j in pairs(v.cast_targets) do 
			local new_mask = self.cast_slotmasks[i]
			if slotmask then 
				slotmask = slotmask + new_mask
			else
				slotmask = new_mask
			end
		end
		self.waypoints[k] = {
			id = v.id,
			text = managers.localization:text(td.premade_text_messages[tostring(v.text_id)]),
			color = v.color,
			texture = texture,
			texture_rect = texture_rect,
			effect = v.effect,
			slotmask = slotmask,
			contextual = v.contextual
		}
	end
	
		--process user-made waypoints (todo)
			--is_localized flag
			
	
	
	--generate radial menu data (creation comes later)
	local radial_menu_data = table.deep_map_copy(self.radial_menu_object_template)
	
	table.insert(radial_menu_data.items,self:GenerateRadialItem("generic"))
	table.insert(radial_menu_data.items,self:GenerateRadialItem("attack"))
	table.insert(radial_menu_data.items,self:GenerateRadialItem("pickup"))
	
	self.radial_menu_data = radial_menu_data
end

Hooks:Add("BaseNetworkSessionOnLoadComplete","quickchat_add_updater",function()
	if managers.hud then 
		managers.hud:add_updator("quickchat_pingmenu_update",callback(QuickChat,QuickChat,"Update"))
	else
		QuickChat:log("ERROR: No hudmanager exists")
	end
end)

function QuickChat:Update(t,dt)
	local ping_menu = self.active_radial_menus.ping_menu
	if ping_menu then 
		local held = HoldTheKey:Key_Held("m")
		if held and not self.input_cache then 
			ping_menu:Show()
		elseif self.input_cache and not held then 
			ping_menu:Hide()
		end
		self.input_cache = held
	end
end

function QuickChat:GenerateRadialItem(id)
	local template_data = self.waypoints[id]
	local new_item 
	if template_data then 
		new_item = table.deep_map_copy(self.radial_menu_item_template)
		new_item.text = template_data.text
		new_item.texture = template_data.texture
		new_item.texture_rect = template_data.texture_rect
		new_item.w = template_data.w
		new_item.h = template_data.h
		new_item.color = template_data.color
		new_item.callback = callback(self,self,"CreatePing",id)
	end
	return new_item
end

function QuickChat:SetRadialMenu(id,menu)
	self.active_radial_menus[id] = menu
end

function QuickChat:PlayCriminalSound(id,sync)
	local player = managers.player:local_player()
	if id and alive(player) then
		id = tostring(id)
		player:sound():say(id,true,sync)
	end
end

function QuickChat:PlayViewmodelAnimation(id)
	local player = managers.player:local_player()
	local movement = alive(player) and player:movement()
	if not (id and movement and movement:in_clean_state()) then 
		movement:current_state():_play_distance_interact_redirect(0, id)
	end
end

	-- Ping creation --
	
--called when the user presses the ping button
--[[
	dofile("mods/PD2-QuickChat/lua/hooks/menumanager.lua")
--]]

function QuickChat:CreatePing(ping_type)
	self:log(tostring(ping_type))
	local params = ping_type and self.waypoints[ping_type]
	if not params then 
		self:log("ERROR: Bad ping_type: QuickChat:CreatePing(" .. tostring(ping_type) .. ")")
		return
	end
	
	local viewport_cam = managers.viewport:get_current_camera()
	if not viewport_cam then 
		--doesn't typically happen, usually for only a brief moment when all four players go into custody
		return 
	end
	
	local cam_pos = viewport_cam:position()
	local cam_aim = viewport_cam:rotation():y()
	local to_pos = (cam_aim * self.tweak_data.max_raycast_distance) + cam_pos
	
	local contextual = params.contextual 
	
	
	local ray = World:raycast("ray",cam_pos,to_pos,"slot_mask",params.slot_mask)
	local hit_unit = ray and ray.unit
	local hit_position = ray and ray.position
	if not (hit_unit or hit_position) then 
		self:log("No unit found!")
		return
	end
	
	if contextual then 
		--autotarget/icon here
	end
	
	if false and params.effect then 
		local effect_position = Vector3()
		
		local parent_object_name = params.effect.parent_object_name
		local parent_object = parent_object and hit_unit:get_object(Idstring(parent_object_name))
		local use_ray_normal = params.effect.use_ray_normal
		local use_hit_position = params.effect.use_hit_position
		local effect_lifetime = params.effect.lifetime
		local effect_rotation = params.effect.rotation
		local effect = World:effect_manager():spawn({
			parent = parent_object,
			position = effect_position,
			rotation = effect_rotation or Rotation(0,0,-90)
		})
		if effect_lifetime then 
			DelayedCallbacks:Add("effect_" .. tostring(unit:key()),effect_lifetime,function()
				if effect and effect ~= -1 then 
					World:effect_manager():kill(effect)
				end
			end)
		end
	end
	
	if params.sound then 
		self:PlayCriminalSound(params.sound,true)
	end
	
	if params.anim then 
		self:PlayViewmodelAnimation(params.anim)
	end
	
	local waypoint_data = table.deep_map_copy(params)
	waypoint_data.ping_type = ping_type
	waypoint_data.hit_unit = hit_unit
	
	--create waypoint panel here
	--if timer is enabled (if modifier key is held), or if waypoint data forces timer, instigate timer
	if self:AddWaypoint(waypoint_data) then
--		self:SyncWaypointToPeers(waypoint_data)
	end
end
	
function QuickChat:AddWaypoint(waypoint_data)
	local parent_panel = managers.hud._workspace:panel()
	if alive(parent_panel) then 
		--create panel for waypoint, and all the bits
		
		local panel = parent_panel:panel({
			name = params.id
		})
		waypoint_data._panel = panel
		waypoint_data._bitmap = panel:bitmap({
			name = "bitmap",
			texture = params.texture,
			texture_rect = params.texture_rect,
			w = params.w,
			h = params.h,
			layer = 2
		})
		
		waypoint_data._text = panel:text({
			name = "text",
			text = tostring(waypoint_data.text),
			align = "center",
	--		x = -100,
	--		y = -100,
			font = "fonts/font_medium_shadow_mf",
			font_size = 24,
			alpha = 0.8,
			layer = 3,
			color = Color.white
		})
		
		local do_workspace = true
		if do_workspace then
			local w = 100
			local h = 600
			local world_w = w * 0.01
			local world_h = h * 0.01
			local ws = self._gui:create_world_workspace(world_w,world_h,Vector3(0,0,0),Vector3(world_w,0,0),Vector3(0,world_h,0))
			ws:set_billboard(Workspace.BILLBOARD_BOTH)
			ws:panel():rect({
				name = "debug",
				color = Color.red,
				alpha = 0.5
			})
			
			local position_offset_x = 0
			local position_offset_y = 0
			local position_offset_z = 0
			local rot = managers.viewport:get_current_camera():rotation()
			local rot_nopitch = Rotation(rot:yaw(),0,rot:pitch())
			local position_offset = Vector3(position_offset_x,position_offset_y,0)
			mvec3_rot(position_offset,rot_nopitch)
			local hit_unit = waypoint_data.hit_unit
			local attachment_obj = hit_unit:get_object(Idstring("Head"))
			local oobb = attachment_obj:oobb()
			local x_axis = rot:x():normalized() * params.world_w
			local y_axis = rot:z():normalized() * params.world_h
			local top_left = oobb:center() + Vector3(0,0,position_offset_z) + position_offset - (x_axis / 2)
			ws:set_linked(world_w,world_h,attachment_obj,top_left,x_axis,y_axis)
			
			waypoint_data._workspace = ws
		end
	end
	
	return false
end

function QuickChat:RemoveWaypoint(user,index)
	local waypoint = self:UnregisterWaypoint(user,index)
	if waypoint then 
		self:FadeoutWaypoint(waypoint)
	end
end

function QuickChat:UnregisterWaypoint(user,index)
	if id64 and index and self.waypoints[id64] and self.waypoints[id64][index] then 
		return table.remove(self.waypoints[id64],index)
	end
end

function QuickChat:FadeoutWaypoint(waypoint_data)
	local function cb_destroy(o)
		waypoint_data._panel = nil
		o:remove()
	end
	local function fadeout_func(o)
		local dt = coroutine.yield()
		over(self:GetWaypointFadeoutDuration(),function(progress)
			local n = 1 - progress
			o:set_alpha(n * n)
		end)
	end
	if waypoint_data._panel then 
		waypoint_data._panel:animate(fadeout_func)
	end
	if waypoint._workspace then 
		self._gui:destroy_workspace(waypoint.workspace)
		waypoint._workspace = nil
	end
end

function QuickChat:ReceiveWaypoint(peer,ping_data)
	local id64 = peer:user_id()
	self.waypoints[id64] = self.waypoints[id64] or {}
	
	if #self.waypoints[id64] >= self:GetMaxPingsPerPlayer() then 
		local old_waypoint = self:RemoveWaypoint(id64,#self.waypoints[id64])
		--fadeout waypoint, not instant removal
	end
	local waypoint_data = self:AddWaypoint(waypoint_data)
	if waypoint_data then 
		table.insert(self.waypoints[id64],waypoint_data)
	end
end


	-- Info getters --
	
function QuickChat:GetWaypointFadeoutDuration()
	return self.settings.waypoint_fadeout_duration
end

function QuickChat:GetSlotmaskFromCastType(cast_type)
	return self.cast_slotmasks[cast_type]
end

function QuickChat:FindTargetUnit(id,mask)
	for _,unit in pairs(World:find_units_quick("all", mask)) do
		if unit:id() == id then
			return unit
		end
	end
end

function QuickChat:GetMaxPingsPerPlayer()
	return self.settings.max_pings_per_player
end



	-- Network/syncing --

function QuickChat:RegisterPeer(peer,data)
	self.registered_peers[peer:user_id()] = {
		version_id = data.version_id
	}
end

function QuickChat:SyncWaypointToPeers(waypoint_data)
	local waypoint_string = self:GetWaypointString(waypoint_data)
	if waypoint_string then 
		local session = managers.network:session()
		for _,peer in pairs(session:all_peers()) do 
			local id64 = peer:user_id()
			local peer_data = self.registered_peers[id64] 
			local network_message = self.tweak_data.current_network_message
			if peer_data and peer_data.version_id then 
				if self._network_data.sync_functions_by_version[peer_data.version_id] then 
					network_message = self._network_data.sync_functions_by_version[peer_data.version_id].add
				end
			end
			LuaNetworking:SendToPeer(peer:id(),network_message,waypoint_string)
		end
	end
end

function QuickChat:GetWaypointString(waypoint_data)
	local message_id
	local custom_text
	local icon_type
	local icon_id
	local duration
	local target_type
	local target_id
	local position
	local destroy_id 
end

--parse incoming data
function QuickChat:SyncAddWaypoint_v1(message)
	local data = string.split(message,"|")
	local min_arguments = 6
	if #data < min_arguments then 
		self:log("ERROR: Not enough arguments in message! (" .. tostring(#data) .. " found, should be >= " .. tostring(min_arguments) .. " < " .. tostring(message) .. " > ")
		return nil
	end
	
	local text_id = data[1]
	local custom_text = data[2]
	local icon_type = data[3] and tonumber(data[3])
	local icon_id = data[4]
	local end_t = data[5] and tonumber(data[5])
	local target_type = data[6] and tonumber(data[6])
	local target_id = data[7] and tonumber(data[7])
	local position = data[8] and math.string_to_vector(data[8])
	local destroy_id = data[9] and tonumber(data[9])
	local operation = data[10] and tonumber(data[10])
	return {
		text_id = text_id,
		custom_text = custom_text,
		icon_type = icon_type,
		icon_id = icon_id,
		end_t = end_t,
		target_type = target_type,
		target_id = target_id,
		position = position,
		destroy_id = destroy_id,
		operation = operation
	}
end

function QuickChat:SyncRemoveWaypoint_v1(message)
	
end

function QuickChat:Register_v1(message)
	return {
		version_id = message
	},3
end

Hooks:Add("NetworkReceivedData", "NetworkReceivedData_QuickChat", function(sender, message_id, message)
	if managers.chat and managers.chat:is_peer_muted(sender) then
		--don't do anything because peer is muted lol
	else
		if QuickChat._network_data.sync_functions_by_name[message_id] then 
			local func_name = QuickChat._network_data.sync_functions_by_name[message_id]
			if type(QuickChat[func_name]) == "function" then 
				local ping_data,operation = QuickChat[func_name](QuickChat,message)
				if not ping_data then 
					QuickChat:log("ERROR: No valid ping_data found! Sender " .. tostring(sender) .. ", message_id " .. tostring(message_id) .. " message < " .. tostring(message) .. " >")
					return
				end
				
				local peer = managers.network:session():peer(sender)
				if peer then 
					if operation == QuickChat.tweak_data.network_operation_ids.REGISTER then 
						self:RegisterPeer(peer,ping_data)
					elseif operation == QuickChat.tweak_data.network_operation_ids.ADD then 
					--create and register waypoint from ping_data
						QuickChat:ReceiveWaypoint(peer,ping_data)
					elseif operation == QuickChat.tweak_data.network_operation_ids.REMOVE then
						QuickChat:RemoveWaypoint(peer,ping_data)
					end
				else
					QuickChat:log("Failed to receive ping data from sender " .. tostring(sender) .. ":" .. tostring(message))
				end
			end
		end
	end
end)


	-- Menu --
Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_QuickChat", function(menu_manager)
	
--	QuickChat.chat_radial = RadialMouseMenu:new(QuickChat._chat_radial_data,callback(QuickChat,QuickChat,"set_chat_radial_menu")) or QuickChat.chat_radial
	
	MenuCallbackHandler.callback_quickchat_mainmenu_close = function(self)
		QuickChat:Save()
	end

	QuickChat:Load()
	QuickChat:OnLoad()
	--after all user waypoints are loaded, 
	--generate the radial menu by combining the template and the selected waypoints data
	local radial_menu_data = QuickChat.radial_menu_data
	RadialMouseMenu:new(radial_menu_data,callback(QuickChat,QuickChat,"SetRadialMenu","ping_menu"))
	
--	MenuHelper:LoadFromJsonFile(QuickChat._menu_path .. "menu/options.txt", QuickChat, QuickChat.settings)		
end)

	
	

	-- I/O --

function QuickChat:Load()
	self:LoadSettings()
	self:LoadWaypoints()
end

function QuickChat:Save()
	self:SaveSettings()
	self:SaveWaypoints()
end

function QuickChat:LoadWaypoints()
	local file = io.open(self._waypoints_save_path, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.user_waypoints[k] = v
		end
	else
		self:SaveWaypoints()
	end
	return self.user_waypoints
end

function QuickChat:SaveWaypoints()
	local file = io.open(self._waypoints_save_path,"w+")
	if file then
		file:write(json.encode(self.user_waypoints))
		file:flush()
		file:close()
	end
end

function QuickChat:LoadSettings()
	local file = io.open(self._save_path, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.settings[k] = v
		end
	else
		self:SaveSettings()
	end
	return self.settings
end

function QuickChat:SaveSettings()
	local file = io.open(self._save_path,"w+")
	if file then
		file:write(json.encode(self.settings))
		file:flush()
		file:close()
	end
end