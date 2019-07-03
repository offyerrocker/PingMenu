--fix pinging item with second ping removing first, if it's yours


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
		sound = "f11e_plu", --if sound is present, plays sound file to all players
		anim = "cmd_come", --if anim is present, performs anim hand viewmodel animation
		timer = 5,
		color = Color(1,0.5,0),
		show_timer = false,
		icon = "wp_standard" --or pd2_generic_look
	},
	{
		name = "Enemy",
		ping_type = "enemy",
		sound = "f42_any", --f45x_any
		anim = "cmd_down",
		timer = 60,
		color = Color(0.7,0.2,0),
		show_timer = false,
		icon = "pd2_kill" or "wp_target"
	},
	{
		name = "Loot",
		ping_type = "loot",
		sound = "g60",
		anim = "cmd_down",
		timer = 5,
		color = Color(1,0.5,0),
		show_timer = false,
		icon = "pd2_loot"
	},
	{
		name = "Attack",
		ping_type = "attack",
		sound = "f02b_sin",
		anim = "cmd_down",
		timer = 5,
		color = Color(1,0.5,0),
		show_timer = false,
		icon = "pd2_melee" or "pd2_power" --idk which to pick
	},
	{
		name = "Get",
		ping_type = "get",
		sound = "g81x_plu",
		anim = "cmd_point",
		timer = 5,
		color = Color(1,0.5,0),
		show_timer = false,
		icon = "pd2_generic_interact"
	},
	{
		name = "Defend",
		ping_type = "defend",
		sound = "g80x_plu",
		anim = "cmd_point",
		timer = 5,
		color = Color(1,0.5,0),
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
		color = Color(1,0.5,0),
		show_timer = true,
		icon = "wp_escort"
	},
	{
		name = "Go",
		ping_type = "go",
		sound = "g13",
		anim = "cmd_gogo",
		timer = 5,
		color = Color(1,0.5,0),
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

function PingMenu:add_waypoint(ping_id,peer_id) --not implemented
	if not peer_id then 
	
	elseif managers.chat and managers.chat:is_peer_muted(peer_id) then
		
	else
	
	end
end


Hooks:Add("NetworkReceivedData", "NetworkReceivedData_PingMenu", function(sender, message_id, message)
	if message_id == PingMenu.mod_id then 
		local waypoint_data = string.split(message,":")
	--make data from message string
--		PingMenu:add_waypoint(sender)
	end
end)


function PingMenu:receive_waypoint_from_peers(ping_id,data) --type of ping

end

function PingMenu:send_waypoint_to_peers(waypoint_num) --number id of ping (1 or 2, or higher if you have set MAX_PINGS_PER_PLAYER higher)
	local waypoint_data = waypoint_num and self.synced_pings[waypoint_num]
	if waypoint_data then 
		local unit = waypoint_data.unit
		local ping_id = waypoint_data.ping_id or 1
		local pos
		if unit then 
			--
		else
			pos = waypoint_data.pos
		end
		if pos then
--send through BLT Networking
			--send: vector3(int x, int y, int z) and ping type (int ping_id) and timer end_t (if applicable)
			local yaw = pos:yaw()
			local pitch = pos:pitch()
			local roll = pos:roll()
			
			if yaw and pitch and roll then 
				
				local message = table.concat({yaw,pitch,roll,ping_id},":")
				LuaNetworking:SendToPeers(PingMenu.mod_id,message)
				--				LuaNetworking:SendToPeers(PingMenu.mod_id,Vector3.ToString(pos))
			end
			
		elseif unit then 
--send through the hacky backwards methods i cooked up BECAUSE UNIT NETWORKING IS NEARLY IMPOSSIBLE ASDJFHAKSJ
			
		else
			self:log("Error: No waypoint target pos/unit to send for own waypoint#" .. tostring(waypoint_num))
			return 
		end
	else
		self:log("Error: No waypoint data to send for own waypoint#" .. tostring(waypoint_num))
	end
end

function PingMenu:_add_waypoint(ping_id,peer_id)

	ping_id = ping_id or 1
	peer_id = peer_id or managers.network:session():local_peer():id() or 1
	local template_data = self.output_data[ping_id]
	local ws = RadialMouseMenu._WS
	if not PingMenu._panel then 
		PingMenu._panel = ws:panel():panel({
			name = "PingMenu_MasterPanel",
			layer = 1
		})
		
		--[[   --experimental pointer
		PingMenu._pointer = PingMenu._panel:bitmap({
			name = "PingMenu_unitpointer",
			texture = tweak_data.hud_icons.wp_arrow.texture,
			texture_rect = tweak_data.hud_icons.wp_arrow.texture_rect,
			layer = 1,
			alpha = 0.5,
			w = 16,
			h = 16,
			x = -1000,
			y = -1000,
			color = Color.white,
			blend_mode = "add"
		})
		local pointer = PingMenu._pointer
		update:
			--draw a pointer line from unit position on screen to given location on screen
		local unit_x,unit_y = unpack(ws:world_to_screen(viewport_cam,unit:position()) --unit position on screen
		local label_x,label_y = 100,200 --hud position on screen
		
		local angle = math.atan((unit_x - label_x) / (unit_y / label_y)) % 180
		pointer:set_rotation(angle)
--	pointer:set_h(something)


		algorithm:
			- init: create two lines on hud
			- given x/y hud positions for selected_unit and hud_panel,
			- measure delta_x against delta_y
			if delta_x is greater, 
				(and if delta_x is above [50px] 
				- horizontal line 1 spans [90]% of distance x
				- remaining 10% of distance x and entirety of distance y is covered by line 2
				- line 2 is diagonal and goes from (unit_x + 0.9*delta_x,unit_y) to (hudpanel_x,hud_panel_y)
			else, 
				- the same thing except vertical
			
			
	
		pseudo: (incomplete)
			y_delta = unit_y - label_y
			x_delta = unit_x - label_x
			
			if math.abs(y_delta) > 10 then 
				y_delta = y_delta - (10 * math.sign(y_delta))
			end
			if math.abs(x_delta) > 10 then 
				x_delta = x_delta - (10 * math.sign(x_delta))
			end
		
		--]]
		
	end
	local panel = PingMenu._panel

	local waypoint_num = 1 + ((#self.synced_pings[peer_id]) % self.MAX_PINGS_PER_PLAYER)
	local waypoint_name = "customping_peer_" .. tostring(peer_id) .. "_" tostring(waypoint_num)
	self:remove_waypoint(waypoint_num,peer_id)
	self:log("Creating waypoint " .. tostring(waypoint_num) .. "," .. tostring(ping_id) .. "," .. tostring(peer_id))
	
	local viewport_cam = managers.viewport:get_current_camera()
	--normally i'd use player fwd_rays but in this case i want spectating (dead) players to be able to place waypoints
	
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
		elseif this_unit:in_slot(8) and alive(this_unit:parent()) then 
			return find_character(this_unit:parent(),true)
		end
	end
	
	if unit and alive(unit) then 
		--types "generic" and "timer" will prioritize characters over interactable units
			--todo weighted angle system rather than precise look-at ray?
	
	
		--types "enemy" and "attack" will prioritize characters (cops, ai, civs) over interactable units
		if is_generic or ping_type == "enemy" or ping_type == "attack" then 
			selected_unit = find_character(unit) or find_interactable(unit)
		end
		
		--types "get" and "loot" will prioritize interactable units over characters
		if not alive(selected_unit) and (is_generic or ping_type == "get" or ping_type == "loot") then 
			selected_unit = find_interactable(unit) or find_character(unit)
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
	
	--create hud elements
	local icontd = tweak_data.hud_icons[tostring(template_data.icon)] or tweak_data.hud_icons.pd2_generic_look
	local icon = panel:bitmap({
		name = "WAYPOINT_ICON_" .. (waypoint_name or "imascrubwhodidntnamemywaypoints"),
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
		name = "WAYPOINT_LABEL_" .. (waypoint_name or "imascrubwhodidntnamemywaypoints"),
		text = "",
--		align = "center",
--		x = -100,
--		y = -100,
		font = tweak_data.hud.medium_font,
		font_size = 12,
		alpha = 0.7,
		layer = 1,
		color = tweak_data.chat_colors[peer_id]
	})
	
	
	local data = {
		name = waypoint_name,
		unit = selected_unit,
		ping_type = template_data.ping_type, --not used atm
		position = position,
		font_size = template_data.font_size, --not defined by default
		timer = template_data.timer,
		timer_linger = template_data.timer_linger,
		show_timer = template_data.show_timer,
		_label = label,
		_icon = icon
	}

	table.insert(self.synced_pings[peer_id],data)

	if template_data.sound and self:SoundEnabled() then 
		self:play_criminal_sound(template_data.sound)
	end
	
	if managers.chat and self:ChatEnabled() and template_data.text then 
--		managers.chat:send_message(ChatManager.GAME, managers.network.account:username() or "Offline", "(Voice) " .. tostring(template_data.text))
	end
	
	if template_data.anim and self:AnimEnabled() then 
		self:play_viewmodel_anim(template_data.anim)
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
			local cyl_radius = 5
			local cyl_height = 1000
			local cyl_alpha = 0.4
			local cyl_lifetime = nil
			local cyl_color = nil
			local font_size = data.font_size or 24
			local cyl_pos_1,cyl_pos_2
			
			if not (data._label and data._icon) then 
--				self:log("PingMenu: ERROR: No waypoint panels found")
				--queue remove?
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
					
					local head = data.unit:get_object(Idstring("Head"))
					if head then 
						pos = head:position()
						cyl_radius = 3
						cyl_alpha = 0.7
						cyl_pos_1 = pos + Vector3(0,0,10)
						cyl_pos_2 = cyl_pos_1
					elseif data.unit.interaction and data.unit:interaction() and data.unit:interaction()._active and not data.unit:interaction()._disabled then --and unit:interaction():active() and not unit:interaction():disabled() then --look for any interactable object
						pos = data.unit:interaction():interact_position()
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
					Console:SetTrackerValue("trackera",angle)
					if angle > 90 then 
						label:set_y(-100000) --i don't want to deal with visible() okay
						icon:set_center(-1000,-1000)
					else
						local icon_pos = ws:world_to_screen(viewport_cam,pos)
						icon:set_center(icon_pos.x,icon_pos.y)

					
						if alive(data.unit) and not data.show_timer then --set unit name and health if applicable
							local unit_name = data.unit.base and data.unit:base() and data.unit:base()._tweak_table
							label:set_text(tostring(unit_name or "UNITNAMEERROR").. " | " .. string.format("%i",unit_name and data.unit.character_damage and data.unit:character_damage()._health or -1))
						end
						local label_x = 16 + icon_pos.x - (label:font_size() * 0.5) 
						local label_y = icon_pos.y - (label:font_size() * 0.5)
						label:set_x(label_x)
						label:set_y(label_y)
						cyl_pos_1 = cyl_pos_1 or pos
						cyl_pos_2 = cyl_pos_2 or pos
			--			Draw:brush((data.color or PingMenu.DEFAULT_PING_COLOR):with_alpha(cyl_alpha),cyl_lifetime):cylinder(cyl_pos_1,cyl_pos_2 + Vector3(0,0,cyl_height),cyl_radius) --update every frame; data.timer not needed (to prevent spam)
						Draw:brush((cyl_color or data.color or PingMenu.DEFAULT_PING_COLOR):with_alpha(cyl_alpha),cyl_lifetime):cylinder(cyl_pos_1,cyl_pos_2 + Vector3(0,0,cyl_height),cyl_radius) --update every frame; data.timer not needed (to prevent spam)
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
		PingMenu:_add_waypoint(num)
	end
--	self:log("released " .. tostring(num))
end)

Hooks:Add("radialmenu_selected_PingMenu","selected_PingMenu_callback",function(num)
	if PingMenu.settings.keybehavior ~= 2 then 
		PingMenu:_add_waypoint(num)
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

function PingMenu:log(...)
	if Console then 
		Console:Log(...,{color = Color.red})
	else
		log(...)
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


	--]]


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
	PingMenu.menu_item = RadialMouseMenu:new(PingMenu.menu_data)
	
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
	
	
		{
			"type" : "toggle",
			"id" : "pingmenu_usechat",
			"title" : "pingmenu_usechat_title",
			"description" : "pingmenu_usechat_desc",
			"callback" : "callback_pingmenu_usechat",
			"value" : "use_chat"
		},
		
		--]]