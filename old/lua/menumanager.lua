--integrate the two mods EVEN MORE:
--ability to add new action radials and edit those action radials' contents
--edit entries in any radial:
	--voiceline or sound (from list)
	--text
	--icon
	--duration


--save current waypoints to table sorted by id64
--re-check peerid on peer list changed
--requires radial mouse menu
--require delayed calls fix?
--integrate with quickchat, since they basically use the same format
--send sounds through luanetworking, add filter option
--todo hook onplayerleft clear waypoints
	--save waypoints in case player rejoins
	--add argument from_rejoin to not flash pings
--add ping sound + variants
--add override file system
--special "follow me" type
--speech bubble?
--animate system






_G.QuickChat = QuickChat or {}

QuickChat._path = QuickChat._path or ModPath
QuickChat._save_path = QuickChat._save_path or SavePath .. "ping_menu_settings.txt"
QuickChat._data_path = QuickChat._save_path .. "ping_menu_data.txt"

QuickChat.mod_id = QuickChat.mod_id or "QuickChat" --for networking reasons


--QuickChat.MAX_PINGS_PER_PLAYER = 2
--for i=1,MAX_NUM_PLAYERS do QuickChat.synced_pings[i] = {} end
QuickChat.synced_pings = {{},{},{},{}}


QuickChat.chat_radial = QuickChat.chat_radial or nil
QuickChat.ping_radial = QuickChat.ping_radial or nil

QuickChat.unit_lookup = {} --lookup by unit:id(), generated/refreshed on receive networked ping

--todo
QuickChat._panel = QuickChat._panel or nil --for pings


QuickChat.settings = {
	pings_enabled = true
}

function QuickChat:IsPingEnabled() --enables ping functionality for current player, and ability to see or receive other players' pings
	return self.settings.pings_enabled
end

--todo test with lootbags
QuickChat.tweak_data = QuickChat.tweak_data or {
	MAX_RAYCAST_DISTANCE = 10000, --100 meters
	DEFAULT_PING_EFFECT = "effects/particles/weapons/flashlight/fp_flashlight_multicolor",
	cast_slotmasks = {
--		enemies = managers.slot:get_mask("enemies"),
--		civilians = managers.slot:get_mask("civilians"),
--		friendlies = managers.slot:get_mask("criminals"),
--		loot = managers.slot:get_mask("interactable"), --todo refactor to mask name?
--		deployables = managers.slot:get_mask("deployables"),
--		generic = managers.slot:get_mask("bullet_targets")
	},
	waypoints = {
		generic = {
			name = "generic",
			text = "$ENEMY $INTERACTABLE $TIMER $ELAPSED",
			color = Color(0,1,1),
			icon = "wp_standard",
			timer = false,
			effect = "default",
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = true,
				loot = true,
				deployables = true
			}
		},
		countdown = {
			name = "countdown",
			text = "$TIMER",
			color = Color(1,1,1),
			icon = "wp_escort",
			timer = 4,
			effect = "default",
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = true,
				loot = true,
				deployables = true
			}
		},
		attack = {
			name = "attack",
			color = Color(1,0.2,0),
			text = "Attack $ENEMY",
			icon = "pd2_kill",
			effect = "default",
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = false, --not sure
				loot = true,
				deployables = false
			}
		}
	}
}

function QuickChat:GetSlotmaskFromCastType(cast_type)
	return self.tweak_data.cast_slotmasks[cast_type]
end

QuickChat.FALLBACK_WAYPOINT_DATA = {
	color = Color.red,
	variant = "attack", --determines text
	_label = Text, --text object generated on creation
	_panel = Panel, --panel object ""
	_icon = Bitmap, --bitmap object ""
	timer = 3, --optional [number], duration in seconds for the waypoint to exist
	start_t = 0, --optional [number], clock time at which waypoint started
--	elapsed = 0, --optional [number], time in seconds that the waypoint has existed
}

function QuickChat:log(a,b,...)
	if Console then 
		Console:Log(a,b,...)
	else
		log("PingMenu: " .. tostring(a))
	end
end

function QuickChat:Init()
	
end

function QuickChat.angle_from(a,b,c,d) -- converts to angle with ranges (-180 , 180); for result range 0-360, do +180 to result
	a = a or "nil"
	b = b or "nil"
	c = c or "nil"
	d = d or "nil"
	local function do_angle(x1,y1,x2,y2)
		local angle = 0
		local x = x2 - x1
		local y = y2 - y1
		if x ~= 0 then 
			angle = math.atan(y / x) % 180
			if y == 0 then 
				if x > 0 then 
					angle = 180 --right
				else
					angle = 0 --left 
				end
			elseif y > 0 then 
				angle = angle - 180
			end
		else
			if y > 0 then
				angle = 270 --up
			else
				angle = 90 --down
			end
		end
		
		return angle
	end
	local vectype = type(Vector3())
	if (type(a) == vectype) and (type(b) == vectype) then  --vector pos diff
		return do_angle(a.x,a.y,b.x,b.y)
	elseif (type(a) == "number") and (type(b) == "number") and (type(c) == "number") and (type(d) == "number") then 
		return do_angle(a,b,c,d)
	else
		return
	end
end

function QuickChat.is_of_type(target_data,target_type)
	if target_data then 
		if target_type == "Vector3" then 
--		return getmetatable(data).__name_id == "Vector3" --pseudo
		end
	end
	return type(target_data) == tostring(target_type)
end

function QuickChat:RegisterUnitById(unit,id)
	if unit and id then 
		self.unit_lookup[id] = unit
	end
end

--Removes the specified unit from the lookup table.
--Returns: the id and unit of the removed unit, or nil.
	--id [Number] the id of the unit to remove. This is the preferred reference for removal.
	--unit [Unit] the direct unit to remove. Optional if you have supplied the id. This is extremely un-ideal as a reference for removal since it will iterate through the entire lookup table.
	--doublecheck [Boolean] If doublecheck, then does check by id (if supplied); if unit by that id did not exist, perform check by unit.
function QuickChat:UnregisterUnit(unit,id,doublecheck)
	if id then 
		local existed = self.unit_lookup[id]
		self.unit_lookup[id] = nil
		if existed or not (doublecheck and unit) then
			return id,existed
		end
	end
	if unit then
		for _id,_unit in pairs(self.unit_lookup) do 
			if _unit == unit then 
				self.unit_lookup[_id] = nil
				return _id,_unit
			end
		end
	end
	return
end

function QuickChat.unit_by_id(id,position,category)
--this function operates on the assumption that physics-enabled entities,
--such as cops, heisters, or lootbags,
--do not necessarily have reliably synced positions between host and clients
--thus, only "stationary" objects such as loot, deployables, and other interactables
--will be searched for by proximity to given starting search vector position
	if id then 
		local lookup_table = QuickChat.unit_lookup
		if lookup_table[id] then 
			return lookup_table[id]
		end
	else
		return
	end
	local function check_category(cat)
		if cat == "enemies" then 
			for ukey,unit in pairs(managers.enemy:all_enemies()) do
				QuickChat:RegisterUnitById(unit,id)
				if unit:id() == id then 
					return unit
				end
			end
		elseif cat == "civilians" then 
			for ukey,unit in pairs(managers.enemy:all_civilians()) do 
				QuickChat:RegisterUnitById(unit,id)
				if unit:id() == id then 
					return unit
				end
			end
		elseif cat == "friendlies" then 
			for ukey,unit in pairs(managers.criminals.criminals) do 
				QuickChat:RegisterUnitById(unit,id)
				if unit:id() == id then 
					return unit
				end
			end
		elseif position then  
			local slotmask = QuickChat:GetSlotmaskFromCastType(cat)
			for ukey,unit in pairs(World:find_units_quick("sphere",position,QuickChat.tweak_data.MAX_RAYCAST_DISTANCE,slotmask)) do 
				QuickChat:RegisterUnitById(unit,id)
				if unit:id() == id then 
					return unit
				end
			end
		end
	end
	if category then 
		if type(category) == "table" then 
			for _,cat in pairs(category) do 
				local unit = check_category(cat,is_dead)
				if unit then 
					return unit
				end
			end
		elseif type(category) == "string" then 
			local unit = check_category(category,is_dead)
			if unit then 
				return unit
			end
		end
	end
	--just do waypoint at position
	return
end

function QuickChat:Update(t,dt)
	if GameStateMachine:verify_game_state(GameStateFilters.any_ingame_playing) then
		--do update keybinds
		local viewport_cam = managers.viewport:get_current_camera()
		if not viewport_cam then
			return
		end
		
		for peer_id,waypoints in pairs(self.synced_pings) do 
			for waypoint_index,waypoint in pairs(waypoints) do 
				if waypoint.timer then 
					if t > waypoint.start_t + waypoint.timer then 
						--queue remove
					end
				end
				
				local position = waypoint.position
				local color = waypoint.color or self.FALLBACK_WAYPOINT_DATA.color
				local effect
				
				
				if alive(waypoint.unit) then
					position = waypoint.unit:position()
				end
				
				--[[
				if waypoint.effect then 
					if waypoint.effect_type == "default" then 
						local opacity_ids = Idstring("opacity")
						local r_ids = Idstring("red")
						local g_ids = Idstring("green")
						local b_ids = Idstring("blue")

						World:effect_manager():set_simulator_var_float(waypoint.effect, r_ids, r_ids, opacity_ids, color.r * opacity)
						World:effect_manager():set_simulator_var_float(waypoint.effect, g_ids, g_ids, opacity_ids, color.g * opacity)
						World:effect_manager():set_simulator_var_float(waypoint.effect, b_ids, b_ids, opacity_ids, color.b * opacity)
					end
				end
			
			--create light
--			World:create_light("spot|specular|plane_projection")
		
--		self._light:set_local_rotation(Rotation())
--		self._light:set_local_position(Vector3())
				--]]
				
--				local angle_to = QuickChat.angle_from(viewport_cam:position(),position)
				local panel_pos = RadialMouseMenu.WS:world_to_screen(viewport_cam,position)
				local panel_x = math.clamp(panel_pos.x,0,panel_w)
				local panel_y = math.clamp(panel_pos.y,0,panel_h)
				waypoint._panel:set_position(panel_x,panel_y)
--				if angle_to > 90 or angle_to < -90 then  
					--todo gather on the screen edge
--				else
					--waypoint._panel:set_center(panel_pos.x - (head and icon:w() or 0),panel_pos.y)
--				end
							
			end
		
		end
		
	end
end

function QuickChat:play_criminal_sound(id,sync)
	local player = managers.player:local_player()
	if id and alive(player) then
		id = tostring(id)
		player:sound():say(id,true,sync)
	end
end

function QuickChat:play_viewmodel_anim(id) --todo sanity checks
	local player = managers.player:local_player()
	local movement = alive(player) and player:movement()
	if not (id and movement and movement:in_clean_state()) then 
		movement:current_state():_play_distance_interact_redirect(0, id) --what is that first arg?
	end
end

function QuickChat:remove_waypoint(peer_id,id) --find by reference and remove
	if id and self.synced_pings[peer_id] then 
		local waypoint = table.remove(self.synced_pings[peer_id],id)
		self:_remove_waypoint(waypoint)
	end
end

function QuickChat:_remove_waypoint(waypoint)
	if waypoint then 
		if alive(waypoint._panel) then 
			waypoint._panel:parent():remove(waypoint._panel)
		end
		if waypoint.effect and waypoint.effect ~= -1 then 
			World:effect_manager():kill(waypoint.effect)
			waypoint.effect = nil
		end
	end
end

function QuickChat:create_ping(ping_type)
	local ping_tweakdata = ping_type and self.tweak_data.waypoints[ping_type]
	if not ping_tweakdata then 
		--error
		return
	end
	
	local viewport_cam = managers.viewport:get_current_camera()
	if not viewport_cam then 
		--doesn't typically happen, usually for only a brief moment when all four players go into custody
		return 
	end
	
	local cam_pos = viewport_cam:position()
	local cam_aim = viewport_cam:rotation():y()
	local to_pos = (cam_aim * self.tweak_data.MAX_RAYCAST_DISTANCE) + cam_pos
	
	--todo multimask
	local ray = World:raycast("ray",cam_pos,to_pos,"slot_mask",managers.slot:get_mask("bullet_impact_targets"))
	if not ray then
		return
	end
	
	local waypoint_data = {} --output
	local unit = ray.unit
	local position = unit:position()

--create beam effect
	local effect_name = ping_tweakdata.effect
	if effect_name then --create effect, if applicable and not extant
		if effect_name == "default" then 
			effect_name = self.tweak_data.DEFAULT_PING_EFFECT
		end
		local effect_position = position
		local effect_parent = unit and unit:get_object(Idstring("Head"))
		if effect_parent then 
			--use parent instead
			effect_position = nil
		end
		local effect = World:effect_manager():spawn({
			--todo set by effect type
			effect = Idstring(effect_name),
			parent = effect_parent,
			position = effect_position,
			rotation = Rotation(0,0,-90)
		})
		if effect and (effect ~= -1) then 
			waypoint_data.effect = effect
			waypoint_data.effect_name = effect_name
		end
	end
	
	local waypoint_id = 1
	
	waypoint_data.position = position
	waypoint.unit = unit
	waypoint.start_t = Application:time()
	waypoint.timer = ping_tweakdata.timer
	waypoint.color = ping_tweakdata.color
	waypoint.icon = ping_tweakdata.icon
	waypoint._panel = self._panel:panel({
		name = waypoint_id,
		w = 200, --todo
		h = 100
	})
	waypoint._bitmap = {}
end

function QuickChat:add_waypoint(peer_id,data)
	
end

function QuickChat:receive_waypoint_from_peers(peer_id,ping_data)
	--ping data should include:
		-- string ping type
		-- bool unit is alive/dead
		-- vector3 position
		-- string cast type(s) (inserted into a table of strings)
end

function QuickChat:send_waypoint_to_peers()
	
end

function QuickChat:set_chat_radial_menu(menu)
	self.chat_radial = menu or self.chat_radial
end

function QuickChat:set_ping_radial_menu(menu)
	self.ping_radial = menu or self.ping_radial
end


QuickChat._chat_radial_data = {
	
}
QuickChat._ping_radial_data = {
	name = "PingMenu",
	radius = 200,
	deadzone = 50,
	items = {
		{
			text = "Ping",
			icon = {
				texture = tweak_data.hud_icons.wp_standard.texture,
				texture_rect = tweak_data.hud_icons.wp_standard.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0) --orange
			},
			callback = callback(QuickChat,QuickChat,"create_ping","generic"),
			show_text = false,
			stay_open = false
		},
		{
			text = "Enemy",
			icon = {
				texture = tweak_data.hud_icons.wp_target.texture,
				texture_rect = tweak_data.hud_icons.wp_target.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.25,0) --red
			},
			callback = callback(QuickChat,QuickChat,"create_ping","enemy"),
			show_text = false,
			stay_open = false
		},
		{
			text = "Loot",
			icon = {
				texture = tweak_data.hud_icons.pd2_lootdrop.texture,
				texture_rect = tweak_data.hud_icons.pd2_lootdrop.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			callback = callback(QuickChat,QuickChat,"create_ping","loot"),
			show_text = false,
			stay_open = false
		},
		{
			text = "Attack",
			icon = {
				texture = tweak_data.hud_icons.pd2_power.texture,
				texture_rect = tweak_data.hud_icons.pd2_power.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			callback = callback(QuickChat,QuickChat,"create_ping","attack"),
			show_text = false,
			stay_open = false
		},
		{
			text = "Get",
			icon = {
				texture = tweak_data.hud_icons.pd2_generic_interact.texture,
				texture_rect = tweak_data.hud_icons.pd2_generic_interact.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			show_text = false,
			stay_open = false
		},
		{
			text = "Defend",
			icon = {
				texture = tweak_data.hud_icons.pd2_defend.texture,
				texture_rect = tweak_data.hud_icons.pd2_defend.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			callback = callback(QuickChat,QuickChat,"create_ping","defend"),
			show_text = false,
			stay_open = false
		},
		{
			text = "Timer",
			icon = {
				texture = tweak_data.hud_icons.pd2_generic_look.texture,
				texture_rect = tweak_data.hud_icons.pd2_generic_look.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			callback = callback(QuickChat,QuickChat,"create_ping","countdown"),
			show_text = false,
			stay_open = false
		},
		{
			text = "Go",
			icon = {
				texture = tweak_data.hud_icons.pd2_goto.texture,
				texture_rect = tweak_data.hud_icons.pd2_goto.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			callback = callback(QuickChat,QuickChat,"create_ping","go"),
			show_text = false,
			stay_open = false
		}
	}
}


function QuickChat:Load()
	local file = io.open(self._save_path, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.settings[k] = v
		end
	else
		self:Save()
	end
	return self.settings
end

function QuickChat:Save()
	local file = io.open(self._save_path,"w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

Hooks:Add("NetworkReceivedData", "NetworkReceivedData_QuickChat", function(sender, message_id, message)
	if message_id == QuickChat.mod_id then 
		if not sender then 
			self:log("Invalid sender")
		elseif managers.chat and managers.chat:is_peer_muted(sender) then
			--don't do anything because peer is muted lol
		else
			local waypoint_data = string.split(message,":")
			local x = waypoint_data[1] and tonumber(waypoint_data[1])
			local y = waypoint_data[2] and tonumber(waypoint_data[2])
			local z = waypoint_data[3] and tonumber(waypoint_data[3])
			local ping_id = waypoint_data[4] and tonumber(waypoint_data[4])
			if x and y and z then 
				QuickChat:receive_waypoint_from_peers(sender,ping_id,Vector3(x,y,z))
			else
				QuickChat:log("Failed to receive ping data from sender " .. tostring(sender) .. ":" .. tostring(message))
			end
		end
	end
end)

Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_QuickChat", function(menu_manager)
	
if managers.slot then 
	QuickChat.tweak_data.cast_slotmasks = {
--		enemies = managers.slot:get_mask("enemies"),
--		civilians = managers.slot:get_mask("civilians"),
--		friendlies = managers.slot:get_mask("criminals"),
--		loot = managers.slot:get_mask("interactable"), --todo refactor to mask name?
--		deployables = managers.slot:get_mask("deployables"),
--		generic = managers.slot:get_mask("bullet_targets")
	}
end
	
	QuickChat.chat_radial = RadialMouseMenu:new(QuickChat._chat_radial_data,callback(QuickChat,QuickChat,"set_chat_radial_menu")) or QuickChat.chat_radial
	QuickChat.ping_radial = RadialMouseMenu:new(QuickChat._ping_radial_data,callback(QuickChat,QuickChat,"set_ping_radial_menu")) or QuickChat.ping_radial
	
	MenuCallbackHandler.callback_pingmenu_mainmenu_close = function(self)
		QuickChat:Save()
	end

	QuickChat:Load()
	
	MenuHelper:LoadFromJsonFile(QuickChat._path .. "menu/options.txt", QuickChat, QuickChat.settings)		
end)



if true then return end
--[[
todo:

--"acknowledge" prompt
--fix doublepings:
		--text and icon should be displayed offset depending on peer_id
--raycast check should be able to tag pickups in addition to bullet_impact_targets slotmask
-- better sync for timer

changelog:

-- separated and organized functions
--	generic and timer ping types now prioritize interactions over entities,
	in order to facilitate duping. i mean what i don't advocate duping
-fixed doublepings from same owner


--]]
_G.PingMenu = {}

PingMenu._path = ModPath
PingMenu._save_path = SavePath

PingMenu.mod_id = "PingMenu"

PingMenu.input_cache = nil
PingMenu.DEFAULT_PING_COLOR = Color(1,0.5,0)
PingMenu.MAX_PINGS_PER_PLAYER = 2
PingMenu.synced_pings = {{},{},{},{}}
PingMenu._panel = nil 

PingMenu.settings = {
--	no_chat = true,
	no_voice = false,
	no_point = false, --anim
	keybehavior = 2 --1 is require hold (select + hide on mouse click), 2 is require hold (select + hide on key release) 3 is toggle (requires mouse)
}

PingMenu.output_data = { --default example quickchat entries; additional lines will be read from saves in the future
	{
		name = "Ping",
		ping_type = "generic",
		sound = "g15", --if sound is present, plays sound file to all players
		anim = "cmd_come", --if anim is present, performs anim hand viewmodel animation
		timer = 5,
		color = Color(1,0.5,0), --Color(0.7,0.2,0),
		show_timer = false,
		icon = "wp_standard" --or pd2_generic_look
	},
	{
		name = "Enemy",
		ping_type = "enemy",
		sound = "f42_any", --f45x_any
		anim = "cmd_point",
		timer = 60,
		color = Color(1,0.8,0),
		show_timer = false,
		icon = "pd2_kill" or "wp_target"
	},
	{
		name = "Loot",
		ping_type = "loot",
		sound = "g15",
		anim = "cmd_down",
		timer = 5,
		color = Color(0,0.7,0),
		show_timer = false,
		icon = "pd2_loot"
	},
	{
		name = "Attack",
		ping_type = "attack",
		sound = "g23",
		anim = "cmd_down",
		timer = 5,
		color = Color(0.7,0,0),
		show_timer = false,
		icon = "pd2_melee" or "pd2_power" --idk which to pick
	},
	{
		name = "Get",
		ping_type = "get",
		sound = "g15",
		anim = "cmd_point",
		timer = 5,
		color = Color(0.7,0.7,0),
		show_timer = false,
		icon = "pd2_generic_interact"
	},
	{
		name = "Defend",
		ping_type = "defend",
		sound = "g16",
		anim = "cmd_point",
		timer = 5,
		color = Color(0,0,0.7),
		show_timer = false,
		icon = "pd2_defend"
	},
	{
		name = "Timer",
		ping_type = "timer",
		sound = "g23",
		anim = "cmd_point",
		timer = 5,
		timer_linger = 1.5, --if specified, waypoint remains for this amount of time afterward
		color = Color(1,1,1),
		show_timer = true,
		icon = "wp_escort"
	},
	{
		name = "Go",
		ping_type = "go",
		sound = "g13",
		anim = "cmd_gogo",
		timer = 5,
		color = Color(0,0.7,0.7),
		show_timer = false,
		icon = "pd2_goto"
	}
}

PingMenu.menu_data = {
	name = "PingMenu",
	radius = 200,
	deadzone = 50,
	items = {
		{
			text = "Ping",
			icon = {
				texture = tweak_data.hud_icons.wp_standard.texture,
				texture_rect = tweak_data.hud_icons.wp_standard.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0) --orange
			},
			show_text = false,
			stay_open = false
		},
		{
			text = "Enemy",
			icon = {
				texture = tweak_data.hud_icons.wp_target.texture,
				texture_rect = tweak_data.hud_icons.wp_target.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.25,0) --red
			},
			show_text = false,
			stay_open = false
		},
		{
			text = "Loot",
			icon = {
				texture = tweak_data.hud_icons.pd2_lootdrop.texture,
				texture_rect = tweak_data.hud_icons.pd2_lootdrop.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			show_text = false,
			stay_open = false
		},
		{
			text = "Attack",
			icon = {
				texture = tweak_data.hud_icons.pd2_power.texture,
				texture_rect = tweak_data.hud_icons.pd2_power.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			show_text = false,
			stay_open = false
		},
		{
			text = "Get",
			icon = {
				texture = tweak_data.hud_icons.pd2_generic_interact.texture,
				texture_rect = tweak_data.hud_icons.pd2_generic_interact.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			show_text = false,
			stay_open = false
		},
		{
			text = "Defend",
			icon = {
				texture = tweak_data.hud_icons.pd2_defend.texture,
				texture_rect = tweak_data.hud_icons.pd2_defend.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			show_text = false,
			stay_open = false
		},
		{
			text = "Timer",
			icon = {
				texture = tweak_data.hud_icons.pd2_generic_look.texture,
				texture_rect = tweak_data.hud_icons.pd2_generic_look.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			show_text = false,
			stay_open = false
		},
		{
			text = "Go",
			icon = {
				texture = tweak_data.hud_icons.pd2_goto.texture,
				texture_rect = tweak_data.hud_icons.pd2_goto.texture_rect,
				layer = 3,
				w = 16,
				h = 16,
				alpha = 0.7,
				color = Color(1,0.5,0)  --orange
			},
			show_text = false,
			stay_open = false
		}
	}
}

function PingMenu:Update()
	if Utils:IsInGameState() then
		if managers.player and managers.player:local_player() and self.menu_item then 
			if self.settings.keybehavior ~= 3 then 
				local held = HoldTheKey:Keybind_Held("pingmenu_show_keybind")
				if held and not self.input_cache then 
					self.menu_item:Show()
				elseif self.input_cache and not held then 
					self.menu_item:Hide()
				end
				self.input_cache = held
			end
		end		
		self:update_waypoints()
	end
end


function PingMenu:receive_waypoint_from_peers(peer_id,ping_id,pos,unit)
	--interpret input
	ping_id = ping_id or 1

	if unit and alive(unit) then 
		
	elseif position and type(position) == type(Vector3()) then 
	
	else
		self:log("ERROR: No position or unit in ping type [" .. tostring(ping_id) .. "] from peer " .. tostring(peer_id))
		return 		
	end

	local template_data = self.output_data[ping_id]
	if not template_data then 
		self:log("Error: Invalid ping data for id " .. tostring(ping_id))
		return 
	end
	local ping_type = template_data.ping_type
	local is_generic = ping_type == "generic" or ping_type == "timer"
	
	
	local data = {
	--name is done in _add_waypoint()
		ping_type = ping_type, --not used atm
		unit = unit, --
		position = position,
		font_size = template_data.font_size, --not defined by default
		timer = template_data.timer,
		timer_linger = template_data.timer_linger,
		show_timer = template_data.show_timer
	--label is done in _add_waypoint()
	--icon is done in _add_waypoint()
	}

	self:_add_waypoint(ping_id,peer_id,data)
end



function PingMenu:_add_waypoint(ping_id,peer_id,data) 
	--add waypoint to self.synced_pings list
	local template_data = self.output_data[ping_id]
	local ws = RadialMouseMenu._WS
	if not PingMenu._panel then 
		PingMenu._panel = ws:panel():panel({
			name = "PingMenu_MasterPanel",
			layer = 1
		})
	end
	
	local panel = PingMenu._panel
	local waypoint_num = 1 + ((#self.synced_pings[peer_id]) % self.MAX_PINGS_PER_PLAYER) --next ping out of [self.MAX_PINGS_PER_PLAYER] pings
	local waypoint_name = "customping_peer_" .. tostring(peer_id) .. "_" .. tostring(waypoint_num)
	
	if data.unit then 
		for other_id,other_ping in pairs(self.synced_pings[peer_id]) do
			if other_ping.unit == data.unit then 
				self:remove_waypoint(other_id,peer_id)
			end
		end
	elseif data.position then
		for other_id,other_ping in pairs(self.synced_pings[peer_id]) do
			if other_ping.position == data.position then 
				self:remove_waypoint(other_id,peer_id)
			end
		end
	end
	
	self:remove_waypoint(waypoint_num,peer_id) --if this waypoint already exists, delete it
	
	local icontd = tweak_data.hud_icons[tostring(template_data.icon)] or tweak_data.hud_icons.pd2_generic_look
	local icon = panel:bitmap({
		name = "WAYPOINT_ICON_" .. waypoint_name,
		texture = icontd.texture,
		texture_rect = icontd.texture_rect,
		layer = 1,
		alpha = 0.7,
		w = 20,
		h = 20,
		x = -100, --start offscreen 
		y = -100,
		color = tweak_data.chat_colors[peer_id] or template_data.color or Color.white,
		blend_mode = "add"
	})
	
	local label = panel:text({
		name = "WAYPOINT_LABEL_" .. waypoint_name,
		text = "",
--		align = "center",
--		x = -100,
--		y = -100,
		font = tweak_data.hud.medium_font,
		font_size = 12,
		alpha = 0.8,
		layer = 1,
		color = tweak_data.chat_colors[peer_id] or template_data.color or Color.white
	})
	data.name = waypoint_name --not really used
	data.color = template_data.color
	data._label = label
	data._icon = icon

	table.insert(self.synced_pings[peer_id],data)
end

Hooks:Add("NetworkReceivedData", "NetworkReceivedData_PingMenu", function(sender, message_id, message)
	if message_id == PingMenu.mod_id then 
		if not sender then 
			self:log("Invalid sender")
		elseif managers.chat and managers.chat:is_peer_muted(sender) then
			--don't do anything because peer is muted lol
		else
			local waypoint_data = string.split(message,":")
			local x = waypoint_data[1] and tonumber(waypoint_data[1])
			local y = waypoint_data[2] and tonumber(waypoint_data[2])
			local z = waypoint_data[3] and tonumber(waypoint_data[3])
			local ping_id = waypoint_data[4] and tonumber(waypoint_data[4])
			if x and y and z then 
				PingMenu:receive_waypoint_from_peers(sender,ping_id,Vector3(x,y,z))
			else
				PingMenu:log("Failed to receive ping data from sender " .. tostring(sender) .. ":" .. tostring(message))
			end
		end
	end
end)

function PingMenu:send_waypoint_to_peers(ping_id,position,unit) 
	if unit and alive(unit) then 
		
		--send through the hacky backwards methods i cooked up BECAUSE UNIT NETWORKING IS NEARLY IMPOSSIBLE ASDJFHAKSJ
	elseif position and type(position) == type(Vector3()) then 
			--send: vector3(int x, int y, int z) and ping type (int ping_id) and timer end_t (if applicable)
		local yaw = pos:yaw()
		local pitch = pos:pitch()
		local roll = pos:roll()
		if yaw and pitch and roll then 
			LuaNetworking:SendToPeers(PingMenu.mod_id,table.concat({yaw,pitch,roll,ping_id},":"))--send through BLT Networking
			--can also use Vector3.ToString(position) but meh
		end
	else
		self:log("ERROR: No position or unit in ping type [" .. tostring(ping_id) .. "] from peer " .. tostring(peer_id))
		return 		
	end
end


function PingMenu:add_waypoint(ping_id) --from local player only
	ping_id = ping_id or 1 --if no type specified, use default ping (happens if you tap the ping key)

	local viewport_cam = managers.viewport:get_current_camera()
	if not viewport_cam then 
		--doesn't typically happen, usually for only a brief moment when all four players go into custody
		return 
	end
	local cam_pos = viewport_cam:position()
	local cam_aim = viewport_cam:rotation():y()
	local to_pos = (cam_aim * 25000) + cam_pos
	
	--[[
	todo change raycast type based on ping type:
	potential alternate slotmasks:
		"player_ground_check"
		"bullet_impact_targets"
		"bullet_impact_targets"
		"pickups"
		"AI_visibility"
		"long_distance_interaction"	
	--]]
	
	--check for relevant nearby objects 
	local ray = World:raycast("ray",cam_pos,to_pos,"slot_mask",managers.slot:get_mask("bullet_impact_targets")) or {}
	local template_data = self.output_data[ping_id]
	if not template_data then 
		self:log("Error: No template data for ping_id " .. tostring(ping_id))
		return
	end
	local ping_type = template_data.ping_type
	local is_generic = ping_type == "generic" or ping_type == "timer"
	
	local waypoint_data = {}
	local selected_unit,position
	local unit = ray.unit
	
	local function find_interactable(this_unit)
		if this_unit.interaction then 
			if this_unit:interaction() and not this_unit:interaction()._disabled and this_unit:interaction()._active then --look for any interactable object
--				self:log("active=" .. tostring(this_unit:interaction()._active) .. ",disabled=".. tostring(this_unit:interaction()._disabled))
				return this_unit
			end
		end
	end
	
	local function find_character(this_unit,no_further)
		if this_unit.character_damage and this_unit:character_damage() and not this_unit:character_damage():dead() then --don't see dead people
			return this_unit
--		elseif this_unit:parent() and alive(this_unit:parent():base()) and this_unit:parent():base().tweak_table then 
		elseif this_unit:in_slot(8) and alive(this_unit:parent()) and not no_further then 
			return find_character(this_unit:parent(),true)
		end
	end
	
	if unit and alive(unit) then 
		--types "generic" and "timer" will prioritize interactable units over characters
			--todo weighted angle system rather than precise look-at ray?
			
		--types "get" and "loot" will prioritize interactable units over characters
		if (is_generic or ping_type == "get" or ping_type == "loot") then 
			selected_unit = find_interactable(unit) or find_character(unit)
		end
		
	
		--types "enemy" and "attack" will prioritize characters (cops, ai, civs) over interactable units
		if not alive(selected_unit) and is_generic or ping_type == "enemy" or ping_type == "attack" then 
			selected_unit = find_character(unit) or find_interactable(unit)
		end

		--types "defend" and "go" will not select units
	end
		
	if not (selected_unit and alive(selected_unit)) then
		position = ray.position
		self:log("No unit or position found. Using raycast position")
	end
	
	if not (position or (selected_unit and alive(selected_unit))) then 
		self:log("Waypoint is missing position and unit!")
		return
	end
	
	local data = {
		ping_type = ping_type or template_data.ping_type, --not used atm
		unit = selected_unit,
		position = position,
		font_size = template_data.font_size, --not defined by default
		timer = template_data.timer,
		timer_linger = template_data.timer_linger,
		show_timer = template_data.show_timer
	}
	
	
	
--	if managers.chat and self:ChatEnabled() and template_data.text then 
--		managers.chat:send_message(ChatManager.GAME, managers.network.account:username() or "Offline", "(Voice) " .. tostring(template_data.text))
--	end
	
	--[[
	--network here?
	if data.unit then 
		if data.unit:network() then 
			data.unit:network():send("sync_player_movement_state",data.ping_type,1,"")
		end
	end

	--]]
	
	self:_add_waypoint(ping_id,managers.network:session():local_peer():id() or 1,data)
	if template_data.anim and self:AnimEnabled() then 
		self:play_viewmodel_anim(template_data.anim)
	end

	if template_data.sound and self:SoundEnabled() then 
		self:play_criminal_sound(template_data.sound)
	end
	
end


function PingMenu:update_waypoints()
	local ws = RadialMouseMenu._WS
	local viewport_cam = managers.viewport:get_current_camera()
	if not (ws and viewport_cam) then return end
	local waypoint_voffset = 100
	local t = Application:time()
	
	local from_pos,to_pos,pos
	local queued_remove = {}
	for peer_id,waypoints in pairs(self.synced_pings) do 
		for i,data in pairs(waypoints) do 
			local cyl_beams = 1 --mini cylinders to fake fadeouts because gradient shading isn't a thing i guess
			--this includes main cylinder beam
			local cyl_radius = 5
			local cyl_height = 300
			local cyl_alpha = 0.4
			local cyl_lifetime = nil
			local cyl_color = nil
			local font_size = data.font_size or 24
			local cyl_pos_1,cyl_pos_2
			local head
			
			if not (data._label and data._icon) then 
				self:log("ERROR: No waypoint panels found")
				--queue remove?
				
--			elseif not (managers.player and alive(managers.player:player_unit(peer_id))) then
				--if player is no longer active (has left lobby, or is custodeady then remove waypoint?
--				table.insert(queued_remove,{id = i,peer_id = peer_id})
			else
				
				local label = data._label
				local icon = data._icon
				if data.unit and alive(data.unit) then 
					--if unit contour then add contour
					
					if data.unit.contour and data.unit:contour() then 
						if data.unit.base and data.unit:base()._tweak_table then 
							--can use mark_enemy
--							self:log("Found contour ".. tostring(data.unit:base()._tweak_table))
							data.unit:contour():add("pingmenu_pingunit_matswap",false)
						else
--							self:log("Found contour")
							data.unit:contour():add("pingmenu_pingunit",false)
						end
					end
					
					
					
					if alive(data.unit) and not data.show_timer then --set unit name and health if applicable
						local unit_name = data.unit.base and data.unit:base() and data.unit:base()._tweak_table
						if unit_name then 
							if managers.enemy:is_civilian(data.unit) then 								
								label:set_text("Civilian")
							else
								label:set_text(tostring(unit_name or "UNITNAMEERROR").. " | " .. string.format("%i",unit_name and data.unit.character_damage and data.unit:character_damage()._health or -1) .. " HP")
							end
						end
					end
					
					head = data.unit:get_object(Idstring("Head"))
					if head then 
						pos = head:position()
						cyl_radius = 3
						cyl_alpha = 0.7
						cyl_pos_1 = pos + Vector3(0,0,10)
						cyl_pos_2 = cyl_pos_1
					elseif data.unit.interaction and data.unit:interaction() and data.unit:interaction()._active and not data.unit:interaction()._disabled then --and unit:interaction():active() and not unit:interaction():disabled() then --look for any interactable object
						pos = data.unit:interaction():interact_position()
						label:set_text(data.unit:interaction().tweak_data or "")
						cyl_radius = 2
						cyl_alpha = 0.3
						cyl_height = 500
--						self:log("Found interact position?" .. tostring(pos))
					else --no head or interact
						self:log("No unit interaction- using unit pos")
						pos = data.unit:position() or pos --unit can be unit or unit's head pos
					end
				elseif data.position then 
					pos = data.position 
				else
					--no valid pos or unit:position() found
					table.insert(queued_remove,{id = i,peer_id = peer_id})
					data.timer = false
					cyl_alpha = 0 --basically invisible
				end
			
				if data.timer then 
					if (not data._timer) or (not data._timer_last) then --slightly more efficient than "not (blank and blank2)"
						data._timer = data.timer + t
						data._timer_last = 0
					end
				
					--effects for "timer"-type ping
					if data.show_timer then 

						--pulse text wane
						if label:font_size() > font_size then
							label:set_font_size(math.max(math.pow(label:font_size(),0.983),font_size))
						end
								
						--only run once every second
						if t > math.ceil(data._timer_last) then
							data._timer_last = t
							local _t = math.floor(data._timer - t)
							
							--pulse text wax; update "timer"-type ping text
							if _t > 0 then 
								label:set_text(string.format("%i",_t))
								label:set_font_size(font_size * ((1 + _t)/_t)) 
							elseif _t == 0 then --reached zero on expiry timer
								label:set_font_size(font_size * 1.60)
								label:set_text("GO!")
								
								icon:set_visible(false) --hide timer progress icon when done
							end
						end	
					end
					
					
					if ((not data._timer_linger) or (t > data._timer_linger)) and t >= data._timer then
					
						if data.timer_linger and not data._timer_linger then -- init timer_linger after initial time runs out
							data._timer_linger = t + data.timer_linger
							--no time left for either
						else --expiry fadeout
							label:set_alpha(label:alpha() * 0.66)
							icon:set_alpha(icon:alpha() * 0.66)
							if label:alpha() <= 0.01 or icon:alpha() <= 0.01 then 
	--							self:log("Queued for removal: " .. tostring(i) .. " from time " .. tostring(data._timer))
								table.insert(queued_remove,{id = i,peer_id = peer_id})
							end
						end
					else --time left
						
						if data.show_timer then 
						
							--set progress circle for "timer"-type ping
							local icon_name = "icon_circlefill" .. string.format("%i",1 + (((data._timer - t) / data.timer) * 16))
							if tweak_data.hud_icons[icon_name] then 
								icon:set_image(tweak_data.hud_icons[icon_name].texture,unpack(tweak_data.hud_icons[icon_name].texture_rect))
							end 
						end
					
					end

				end

				if pos then 
					--update icon/label position
					
					local angle = mvector3.angle(viewport_cam:rotation():y(), pos - viewport_cam:position())
--					Console:SetTrackerValue("trackera",angle)
					if angle > 90 then 
						label:set_y(-100000) --i don't want to deal with visible() okay
						icon:set_center(-1000,-1000)
					else
						local panel_pos = ws:world_to_screen(viewport_cam,pos)
						icon:set_center(panel_pos.x - (head and icon:w() or 0),panel_pos.y)
						
						local label_x = panel_pos.x + (icon:w() * 0.5) --horizontally offset right by half icon size
						local label_y = panel_pos.y - (label:font_size() * 0.5) --vertically centered 
						label:set_x(label_x)
						label:set_y(label_y)
						cyl_pos_1 = cyl_pos_1 or pos
						cyl_pos_2 = cyl_pos_2 or pos
			--			Draw:brush((data.color or PingMenu.DEFAULT_PING_COLOR):with_alpha(cyl_alpha),cyl_lifetime):cylinder(cyl_pos_1,cyl_pos_2 + Vector3(0,0,cyl_height),cyl_radius) --update every frame; data.timer not needed (to prevent spam)
						if cyl_alpha > 0 then 
							for j = 1,cyl_beams do 
--								if j == cyl_beams then 
									Draw:brush((cyl_color or data.color or PingMenu.DEFAULT_PING_COLOR):with_alpha(cyl_alpha),cyl_lifetime):cone(cyl_pos_2 + Vector3(0,0,cyl_height),cyl_pos_2,cyl_radius)
--									Draw:brush(data.color:with_alpha(cyl_alpha)):cone(cyl_pos_2,cyl_pos_1,cyl_radius,1000)
--								else
--									Draw:brush((cyl_color or data.color or PingMenu.DEFAULT_PING_COLOR):with_alpha(cyl_alpha),cyl_lifetime):cylinder(cyl_pos_1,cyl_pos_2 + Vector3(0,0,cyl_height),cyl_radius)
--								end
								cyl_height = cyl_height * 0.66
								cyl_pos_1 = mvector3.copy(cyl_pos_2)
								cyl_pos_2 = cyl_pos_2 + Vector3(0,0,cyl_height)
								cyl_radius = cyl_radius * 0.75
								cyl_alpha = cyl_alpha * 0.85
							end
						end
					end
				end
			end
	
		end
	end
	
	for _,wp in pairs(queued_remove) do 
		self:remove_waypoint(wp.id,wp.peer_id)
	end
end




Hooks:Add("radialmenu_released_PingMenu","released_PingMenu_callback",function(num)
	if PingMenu.settings.keybehavior == 2 then	
		PingMenu:add_waypoint(num)
	end
--	self:log("released " .. tostring(num))
end)

Hooks:Add("radialmenu_selected_PingMenu","selected_PingMenu_callback",function(num)
	if PingMenu.settings.keybehavior ~= 2 then 
		PingMenu:add_waypoint(num)
	end
--	self:log("pressed " .. tostring(num))
end)

function PingMenu:remove_waypoint(id,peer_id)
	self:log("Removing waypoint " .. tostring(peer_id) .. "," .. tostring(ping_id) .. "/" .. tostring(#self.synced_pings[peer_id]))
	local this = self.synced_pings[peer_id][id]
	
	if this then 
		self:log("Removed waypoint " .. tostring(peer_id) .. "," .. tostring(ping_id))
		PingMenu._panel:remove(this._icon)
		PingMenu._panel:remove(this._label)
		this._icon = nil
		this._label = nil
	end
	table.remove(self.synced_pings[peer_id],id)
end

function PingMenu:log(a,...)
	if Console then 
		Console:Log(a,...,{color = self.DEFAULT_PING_COLOR})
	else
		log("PingMenu: " .. tostring(a),...)
	end
end
	
function PingMenu:AnimEnabled()
	return not self.settings.no_point
end
		
function PingMenu:SoundEnabled()
	return not self.settings.no_voice
end

function PingMenu:play_criminal_sound(id)
	local player = managers.player:local_player()
	if id and player then
		id = tostring(id)
		player:sound():say(id,true,true)
	else
		return
	end
end

function PingMenu:play_viewmodel_anim(id) --todo sanity checks
	local player = managers.player:local_player()
	local movement = player and player:movement()
	if not (id and movement and movement:in_clean_state()) then 
		movement:current_state():_play_distance_interact_redirect(0, id)
	end
end

function PingMenu:set_radial_menu(menu)
	self.menu_item = self.menu_item or menu
end

function PingMenu:Load()
	local file = io.open(self._save_path, "r")
	if (file) then
		for k, v in pairs(json.decode(file:read("*all"))) do
			self.settings[k] = v
		end
	else
		self:Save() --create data in case there's no mod save data
	end
	return self.settings
end

function PingMenu:Save()
	local file = io.open(self._save_path,"w+")
	if file then
		file:write(json.encode(self.settings))
		file:close()
	end
end

Hooks:Add("LocalizationManagerPostInit", "PingMenu_LocalizationManagerPostInit", function( loc )
	for _, filename in pairs(file.GetFiles(PingMenu._path .. "loc/")) do
		local str = filename:match('^(.*).txt$')
		if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
			loc:load_localization_file(PingMenu._path .. "loc/" .. filename)
			return
		end
	end
	loc:load_localization_file( PingMenu._path .. "loc/english.txt")
end)

Hooks:Add("MenuManagerInitialize", "PingMenu_MenuManagerInitialize", function(menu_manager)
	
	MenuCallbackHandler.callback_pingmenu_show = function(self)
		if PingMenu.settings.keybehavior == 3 then 
			PingMenu.menu_item:Toggle()
		end
	end
	PingMenu.menu_item = RadialMouseMenu:new(PingMenu.menu_data,callback(PingMenu,PingMenu,"set_radial_menu"))
	
	--menu toggle
	MenuCallbackHandler.callback_pingmenu_useanim = function(self,item)
		local value = item:value() == "on"
		PingMenu.settings.use_chat = value
		PingMenu:Save()
	end
	
	MenuCallbackHandler.callback_pingmenu_usevoice = function(self,item)
		local value = item:value() == "on"
		PingMenu.settings.use_voice = value
		PingMenu:Save()
	end
	
	MenuCallbackHandler.callback_pingmenu_usechat = function(self,item)
		local value = item:value() == "on"
		PingMenu.settings.use_text = value
		PingMenu:Save()
	end

	MenuCallbackHandler.callback_pingmenu_keybehavior = function(self,item)
		local value = tonumber(item:value())
		PingMenu.settings.keybehavior = value
		PingMenu:Save()
	end

	--close
	MenuCallbackHandler.callback_pingmenu_mainmenu_close = function(this)
		PingMenu:Save()
	end

	PingMenu:Load()
	
	MenuHelper:LoadFromJsonFile(PingMenu._path .. "menu/options.txt", PingMenu, PingMenu.settings)		
end)
	
--[[
	
	
function PingMenu:GetRadialMenu(id)
	return self.radial_items[id]
end
function PingMenu:Open_Customize_Menu(num)

	local options = {}
	
--	options[#options + 1] = {
--	text = "",
-- callback = callback(self,self,"Open_Customize_Menu")
--}
	
	PingMenu:new("PingMenu Customization Menu","Current Chat command:",options):show()
	--todo create "callback" flag so that input is only unblocked after the chat command is complete
end

function QuickChat:ToggleRadial(id)
	if self.menu_item then 
		self.menu_item:Toggle()
	end

	for i,radial in pairs(self.radial_items) do 
		if i == id then 
			radial:Toggle()
		else
			radial:Hide()
		end
	end
end


function PingMenu:ChatEnabled()
	return not self.settings.no_chat
end

function PingMenu:do_output(ping_id,peer_id) --old
	ping_id = ping_id or 1
	peer_id = peer_id or managers.network:session():local_peer():id() or 5
	local data = self.output_data[ping_id]

	local waypoint_num = 1 + ((1 + #self.synced_pings[peer_id]) % self.MAX_PINGS_PER_PLAYER)
	local waypoint_name = "customping_peer_" .. tostring(waypoint_num)

	local is_generic = (data.name == "Ping") or (data.name == "Timer")
	
--	local player = managers.player:local_player()
--	local pos = player and player:position()
	local fwd_ray = player and player:movement():current_state()._fwd_ray or {}
	local look_at_pos = fwd_ray.position
	
	local pos
	local unit 
	
	--return managers.player:local_player():movement():current_state()._fwd_ray.unit:interaction().tweak_data
	local done = false
	
	if true then 
	
	
	
		return 
	end
	
	if is_generic or data.name == "Enemy" or data.name == "Attack" then 
		if data.unit and data.unit.character_damage then 
			unit = data.unit
			done = true
		end
	end
	
	if not done and (is_generic or data.name == "Get" or data.name == "Loot") then 
		if data.unit and data.unit.base and data.unit.interaction and data.unit:interaction() then 
			unit = data.unit
			done = true
			--set name to bag name or interaction name
		end
		--check if unit is bodybag or lootbag or interactable
		--check if unit is interactable
	end
	if not done and data.name == "Defend" then 
		--area waypoint
	end
	if not done and data.name == "Go" then 
		--area waypoint
	end

	pos = pos or look_at_pos

	if managers.hud then
		managers.hud:remove_waypoint(waypoint_name)
		
		managers.hud:add_waypoint(
			waypoint_name,
			{
				icon = data.icon or "pd2_generic_look",
				distance = false,
--				name = data.name,
				position = pos,
				no_sync = false,
				present_timer = 0,
				state = "present",
				radius = 50,
--				slot_x = 0,
--				slot_y = 0,
				unit = unit,
--				timer = 3,
--				present_timer = 3,
--				state = "offscreen",
--				radius = 10,
				blend_mode = "add",
				color = tweak_data.preplanning_peer_colors[peer_id]
			} 
		)
	end
end

function PingMenu:generate_waypoint_data(index,peer_id) --old
	peer_id = peer_id or 1
	index = index or 1
	local ws = RadialMouseMenu._WS
	local panel = PingMenu._panel
	local data = self.synced_pings[peer_id][index]
	--data._timer_last = data._timer
	if not data then return end
	
	local icontd = tweak_data.hud_icons[data.icon or "pd2_generic_look"]
	local icon = panel:bitmap({
		name = "WAYPOINT_ICON_" .. (data.name or ""),
		texture = icontd.texture,
		texture_rect = icontd.texture_rect,
		layer = 1,
		alpha = 0,
		w = 16,
		h = 16,
		blend_mode = "add"
	})
	data._icon = icon
	
	local label = panel:text({
		name = "WAYPOINT_LABEL_" .. (data.name or ""),
		text = "",
		align = "center",
		font = tweak_data.hud.medium_font,
		font_size = 12,
		alpha = 0,
		layer = 1,
		color = data.color or Color.white
	})
	data._label = label
	return icon,label
end



		{
			"type" : "toggle",
			"id" : "pingmenu_usechat",
			"title" : "pingmenu_usechat_title",
			"description" : "pingmenu_usechat_desc",
			"callback" : "callback_pingmenu_usechat",
			"value" : "use_chat"
		},
		
		--]]