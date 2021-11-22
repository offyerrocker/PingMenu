--[[ i have started, stopped, made working prototypes for, scrapped, and restarted this mod no less than 7 times at various points in my time modding this game

	dofile("mods/PD2-QuickChat/lua/hooks/menumanager.lua")

	
todo: 
	-resolve wall-ping behavior
		glowing circle for positional markers (spotlight + circle graphic aligned against normal dir; repurpose waypoint)
	vertical waypoint offset (by screen instead of by world)
	offscreen waypoint position updating
	prevent ADS when exiting radial menu with rightclick
	conceptually resolve desync issue
	case-specific ping types for contextual pings
	-optional "[You] pinged [object]" message in local chat
	-chat cooldown
--radial menu
	--custom radial menu graphics
	--adjust position of text
	--adjust size
--closed captions compatibility?
--customization
	--edit action radials
	--add and custom keybind N number of action radials in menu?
--menu to manually clear waypoints from any or all player(s)
--hold button to switch to n-second timer?
--timer icon should be separate from normal icon
--register to peers on connected
--don't bother filtering naughty words. anyone who wanted to cuss or toss epithets around could just use chat anyhow
--slow fade remove while still updating positions (low priority)
--better glow/beacon effect for waypoints

specific voiceline cases:
--jammed drill
--keycard (v10)
--crowbar (v57)
--door (v15/16)
--shoot camera g25
--camera mark (f39_any)
--guard mark (f37_any)
--civilian (watch the civilians g27 / use cable ties g26)
--loot bag with legs (p31)
--(move) loot bag (v51)
--special marking?
--hostage trade p07
--escape zone (there's our ride v26 / we gotta get out g07)
--vehicle v26
--flashbang g41x_any

general voicelines:
--look here!
--interact with this
--pick this up/loot this
--attack (v49 shoot it down, fire at it / )
--go (come with me p20 / hurry g06 / inspire basic g18 / right way g12 / let's go g13 / move p14 / get moving p15 / MOVE p16 / follow me f38_any / time to go g17)
--search (search the place v38 / keep looking v44 )
--wait (f48x_any p04)
--defend g16


anims:
cmd_come
cmd_point
cmd_down
cmd_gogo

schema:
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


local mrot_y = mrotation.y
local mvec3_rot = mvector3.rotate_with
local mvec3_nrm = mvector3.normalize
local mvec3_dot = mvector3.dot
local mvec3_copy = mvector3.copy
local mvec3_add = mvector3.add


	-- Init mod values --
QuickChat = QuickChat or {}
QuickChat._mod_path = ModQuickChat and ModQuickChat.GetPath and ModQuickChat:GetPath() or ModPath
QuickChat._localization_path = QuickChat._mod_path .. "localization/"
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
	debug_log_enabled = true,
	max_pings_per_player = 3,
	waypoint_fadeout_duration = 1
}
QuickChat.settings = QuickChat.settings or table.deep_map_copy(QuickChat.default_settings)

QuickChat.radial_menu_object_template = {
	name = "PingMenu",
	radius = 600,
	deadzone = 100,
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

QuickChat.USER_ID = QuickChat.USER_ID or "local_user"

QuickChat.tweak_data = QuickChat.tweak_data or {
	current_network_message = "QuickChat_v1_Add",
	network_operation_ids = {
		REGISTER = 1,
		ADD = 2,
		REMOVE = 3
	}, 
	beam_height = 1000, --centimeters
	beam_radius = 1, --centimeters
	waypoint_icon_vertical_offset = -1000, --pixels
	default_waypoints = {
		generic = {
			id = "generic",
			text_id = "text_look",
			color = Color(0,1,1),
			icon_id = "wp_standard",
			icon_type = 1, --1 = hudiconstweakdata, 2 = premade
			effect = "default",
			sound_id = "g15",
			anim_id = "cmd_point",
			create_ping = true,
			contextual = true,
			show_distance = true,
			show_timer = false,
			use_timer = false,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = true,
				pickups = true,
				deployables = true
			}
		},
		attack = {
			id = "attack",
			color = Color(1,0.2,0),
			text_id = "text_attack",
			icon_id = "pd2_kill",
			icon_type = 1,
			effect = "default",
			sound_id = "g23", --"shoot em!" or "v18" for "wipe em out/clear the room"
			anim_id = "cmd_point",
			create_ping = true,
			show_distance = true,
			show_timer = false,
			use_timer = false,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = false, --not sure
				pickups = false,
				deployables = false
			}
		},
		pickup = {
			id = "pickup",
			color = Color(1,0.2,0),
			text_id = "text_pickup",
			icon_id = "icon_pickup",
			icon_type = 2,
			texture = "guis/textures/hud_icons",
			texture_rect = {
				0,
				192,
				45,
				50
			},
			effect = "default",
			sound_id = "v04", --"found it, it's here"
			anim_id = "cmd_point",
			create_ping = true,
			show_distance = true,
			show_timer = false,
			use_timer = false,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = false, --not sure
				pickups = true,
				deployables = false
			}
		},
		interact = {
			id = "interact",
			color = Color(1,0.2,0),
			text_id = "text_interact",
			icon_id = "equipment_doctor_bag",
			icon_type = 1,
			effect = "default",
			sound_id = "v44",
			anim_id = "cmd_point",
			create_ping = true,
			show_distance = true,
			show_timer = false,
			use_timer = false,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = false, --not sure
				pickups = false,
				deployables = false
			}
		}
	},
	max_raycast_distance = 10000, --100 meters
	contextual_interactions = {
		revive = {
			target_category = "menu_ping_category_ally_downed",
			target_name = "Ally" --overridden, special behavior case
		},
		hostage_skm = {
			target_category = "menu_ping_category_hostage",
			target_name = "menu_ping_hostage_vip"
		},
		hostage_trade = {
			target_category = "menu_ping_category_hostage",
			target_name = "menu_ping_hostage_vip"
		},
		hostage_move = {
			target_category = "menu_ping_category_hostage",
			target_name = "menu_ping_hostage_vip"
		},
		hostage_stay = {
			target_category = "menu_ping_category_hostage",
			target_name = "menu_ping_hostage_vip"
		},
		trip_mine = {
			target_category = "menu_ping_category_deployable",
			target_name = "debug_trip_mine"
		},
		sentry_gun_refill = {
			target_category = "menu_ping_category_deployable",
			target_name = "debug_sentry_gun"
		},
		sentry_gun_revive = {
			target_category = "menu_ping_category_deployable",
			target_name = "debug_sentry_gun"
		},
		sentry_gun = {
			target_category = "menu_ping_category_deployable",
			target_name = "debug_sentry_gun"
		},
		sentry_gun_fire_mode = {
			target_category = "menu_ping_category_deployable",
			target_name = "debug_sentry_gun"
		},
		bodybags_bag = {
			target_category = "menu_ping_category_deployable",
			target_name = "debug_sentry_gun"
		},
		grenade_crate = {
			target_category = "menu_ping_category_deployable",
			target_name = "debug_grenade_crate"
		},
		ammo_bag = {
			target_category = "menu_ping_category_deployable",
			target_name = "debug_ammo_bag"
		},
		doctor_bag = {
			target_category = "menu_ping_category_deployable",
			target_name = "debug_doctor_bag"
		},
		ecm_jammer = {
			target_category = "menu_ping_category_deployable",
			target_name = "debug_ecm_jammer"
		}
	},
	premade_text_messages = {
		text_pickup = "menu_ping_pickup_label", --get this thing!
		text_interact = "menu_ping_interact_label", --use this thing!
		text_attack = "menu_ping_attack_label", --attack this thing!
		text_look = "menu_ping_look_label" --look at this thing!
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
		deployables = "deployables",
		generic = "bullet_impact_targets",
		world = {"world_geometry"},
		pickups = "pickups"
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
QuickChat.num_waypoints = QuickChat.num_waypoints or 0

--the custom waypoints for the user (not yet implemented)
QuickChat.user_waypoints = QuickChat.user_waypoints or {
--[[

--]]
}

--all waypoints (combined user_waypoints and default_waypoints), processed
QuickChat.waypoint_parameters = QuickChat.waypoint_parameters or {}



 --the waypoints placed by someone in the current game
QuickChat.active_waypoints = QuickChat.active_waypoints or {}

QuickChat.registered_peers = QuickChat.registered_peers or {
	--[[
		[id64] = {
			version_id = "1"
		},
	--]]
}


QuickChat.cast_slotmasks = QuickChat.cast_slotmasks or {} --populated on load

QuickChat.active_radial_menus = QuickChat.active_radial_menus or {}


	-- Settings getters --
	
function QuickChat:GetWaypointFadeoutDuration()
	return self.settings.waypoint_fadeout_duration
end

function QuickChat:GetSlotmaskFromCastType(cast_type)
	return self.cast_slotmasks[cast_type]
end

function QuickChat:GetMaxPingsPerPlayer()
	return self.settings.max_pings_per_player
end

	-- General functions --

function QuickChat:log(...)
	if self.settings.debug_log_enabled then 
		if _G.Log then 
			return _G.Log(...)
		end
		return log(...)
	end
end

function QuickChat:PopulateSlotmaskData()
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
	
end

function QuickChat:PopulateDefaultWaypointData()
	local td = self.tweak_data
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
		self.waypoint_parameters[k] = {
			id = v.id,
			text = managers.localization:text(td.premade_text_messages[tostring(v.text_id)]),
			color = v.color,
			texture = texture,
			texture_rect = texture_rect,
			effect = v.effect,
			slotmask = slotmask,
			contextual = v.contextual,
			icon_id = v.icon_id,
			icon_type = v.icon_type,
			sound_id = v.sound_id,
			create_ping = v.create_ping,
			show_distance = v.show_distance,
			show_timer = v.show_timer,
			use_timer = v.use_timer,
			anim_id = v.anim_id
		}
	end
end

function QuickChat:PopulateUserWaypointData()
	--process user-made waypoints (todo)
		--don't forget the is_localized flag
end

function QuickChat:CreateRadialMenus()
	--generate radial menu data (creation comes later)
	local radial_menu_data = table.deep_map_copy(self.radial_menu_object_template)
	
	table.insert(radial_menu_data.items,self:GenerateRadialItem("generic"))
	table.insert(radial_menu_data.items,self:GenerateRadialItem("attack"))
	table.insert(radial_menu_data.items,self:GenerateRadialItem("pickup"))
	
	self.radial_menu_data = radial_menu_data
end

function QuickChat:GenerateRadialItem(id)
	local template_data = self.waypoint_parameters[id]
	local new_item 
	if template_data then 
		new_item = table.deep_map_copy(self.radial_menu_item_template)
		new_item.text = template_data.text
		new_item.icon = {
			texture = template_data.texture,
			texture_rect = template_data.texture_rect,
			w = template_data.w,
			h = template_data.h,
			color = template_data.color
		}
		new_item.callback = callback(self,self,"CreatePing",id)
	end
	return new_item
end

function QuickChat:SetRadialMenu(id,menu)
	self.active_radial_menus[id] = menu
	menu.Hide = function(self,skip_reset,do_success_cb)
		if not skip_reset then 
			RadialMouseMenu.current_menu = nil
		end
		self._hud:hide()
	--	RadialMouseMenu._WS:disconnect_keyboard()
		if self.block_all_input then 
			game_state_machine:_set_controller_enabled(true)
		end
		local item = self._selected and self._items[self._selected]
		self._selected = false
		if self._active then 
			self._active = false
			self._selector:set_visible(false)
			local player = managers.player and managers.player:local_player()
			if alive(player) then 
				player:movement():current_state()._menu_closed_fire_cooldown = player:movement():current_state()._menu_closed_fire_cooldown + 0.01
			end
			self:on_closed()
			managers.mouse_pointer:remove_mouse(RadialMouseMenu.MOUSE_ID)
			if do_success_cb then 
				if item then 
					self:on_item_clicked(item,true) --already hiding here so skip_hide 
				else
					QuickChat:CreatePing("generic")
				end
			end
		end
	end
	
	menu.mouse_clicked = function (self,o,button,x,y)
		if button == Idstring("1") then  --rightclick
			self:Hide(nil,false)
		elseif button == Idstring("0") then --leftclick`
			local item = self._selected and self._items[self._selected]
			if item then 
				self:on_item_clicked(item)
			end
		end
	end
	
end

function QuickChat:OnLoad()
	self._gui = self._gui or World:newgui()
	self.active_waypoints[self.USER_ID] = self.active_waypoints[self.USER_ID] or {}
	
	self:PopulateSlotmaskData()
	
	self:PopulateDefaultWaypointData()

	self:CreateRadialMenus()
end

Hooks:Add("BaseNetworkSessionOnLoadComplete","quickchat_add_updater",function()
	if managers.hud then 
		managers.hud:add_updator("quickchat_pingmenu_update",callback(QuickChat,QuickChat,"Update"))
	else
		QuickChat:log("ERROR: Could not create updator; no hudmanager exists")
	end
end)

function QuickChat:Update(t,dt)
	self:UpdateInput(t,dt)
	self:UpdateWaypoints(t,dt)
end

function QuickChat:UpdateInput(t,dt)
	local ping_menu = self.active_radial_menus.ping_menu
	if ping_menu then 
		local held = HoldTheKey:Key_Held("m")
		if held and not self.input_cache then 
			ping_menu:Show()
		elseif self.input_cache and not held then 
			ping_menu:Hide(nil,true)
		end
		self.input_cache = held
	end
end

function QuickChat:UpdateWaypoints(t,dt)

	local camera = managers.viewport:get_current_camera()
	if not camera then 
		return
	end
	local cam_pos = camera:position()
	local cam_rot = camera:rotation()
	local cam_dir = cam_rot:y():normalized()
	
	local workspace = managers.hud._workspace
	local parent_panel = workspace:panel()
	
	for user_id,waypoints_list in pairs(self.active_waypoints) do 
		for i=#waypoints_list,1,-1 do 
			local queued_remove
			
			local waypoint_data = waypoints_list[i]
			local color = waypoint_data.color or Color.white
			local beam_color = waypoint_data.beam_color or tweak_data.chat_colors[5]
			local unit = waypoint_data.unit
			local ping_type = waypoint_data.ping_type
			local panel = waypoint_data._panel
			local text = waypoint_data._text
			local bitmap = waypoint_data._bitmap
			local x_offset = waypoint_data.x_offset or 0
			local light = waypoint_data._light
			
			--check for timeout
			if waypoint_data.end_t then 
				if t > waypoint_data.end_t then 
					queued_remove = true
				end
			end

			if not queued_remove then 
				--check for dead
				if waypoint_data.is_dead == false then 
					if unit:character_damage():dead() then 
						queued_remove = true
					end
				end
				
				--update position on screen
				
					
				local target_position = waypoint_data.position
				if not waypoint_data.is_world and alive(unit) then 
					local obj
					if is_character then 
						obj = unit:get_object(Idstring("Head"))
						if obj then 
							target_position = obj:oobb():center()
						elseif unit:movement() and unit:movement().m_head_pos then 
							target_position = unit:movement():m_head_pos()
						else
							obj = unit:orientation_object()
							if obj then 
								target_position = obj:oobb():center()
							end
						end
					end
				end
				if light then 
					local light_position = target_position + Vector3(0,0,150)
					light:set_position(light_position)
					Draw:brush(Color.white):sphere(light_position,10)
--					local r = light:rotation()
--					light:set_rotation(Rotation(r:yaw(),r:pitch() + (dt * 360),r:roll()))
				end
				
--				local from_pos,to_pos,pos
				if target_position then 
					local orig_position = mvec3_copy(target_position)
					
				--draw beam
					Draw:brush(beam_color:with_alpha(0.25)):cone(orig_position + Vector3(0,0,self.tweak_data.beam_height),orig_position,self.tweak_data.beam_radius)
					
					
					local pos = workspace:world_to_screen(camera,target_position)
					pos.y = pos.y + self.tweak_data.waypoint_icon_vertical_offset
					local panel_w,panel_h = panel:size()
					
					local dir_to = target_position - cam_pos
					local dot = mvector3.dot(cam_dir:normalized(),dir_to:normalized())
--					Console:SetTrackerValue("trackera",tostring(dot))
					text:set_alpha(math.clamp(dot * 100, 0.1, 1))
					
					
--					if dot > 0 then 
--						if dot < 0.5 then 
							if pos.x > parent_panel:w() - panel_w then 
								panel:set_right(parent_panel:w() + x_offset)
							else
								panel:set_left(math.max(0,pos.x) + x_offset)
							end
							
							if pos.y > parent_panel:h() - panel_h then 
								panel:set_bottom(parent_panel:h())
							else
								panel:set_top(math.max(0,pos.y))
							end
--						else
--						end
--					else						
--					end
					
					
				else
					self:log("ERROR: No target position found for waypoint uid " .. tostring(waypoint_data.destroy_id))
				end
				
				
			end
			
			if queued_remove then 
				self:RemoveWaypoint(user_id,i)
			end
		end
	end
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

--used for incoming sync waypoints
function QuickChat:FindTargetUnit(id,mask)
	for _,unit in pairs(World:find_units_quick("all", mask)) do
		if unit:id() == id then
			return unit
		end
	end
end

	-- Ping creation --
	
--called when the user presses the ping button

--on pressing the ping button, raycast for a valid target/position
--then generate data for that waypoint accordingly
function QuickChat:CreatePing(ping_type)
	local params = ping_type and self.waypoint_parameters[ping_type]
	if not params then 
		self:log("ERROR: Bad ping_type: QuickChat:CreatePing(" .. tostring(ping_type) .. ")")
		return
	end
	if not params.create_ping then 
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
	
	local ray = World:raycast("ray",cam_pos,to_pos,"slot_mask",params.slotmask + self.cast_slotmasks.generic)
	local hit_unit = ray and ray.unit
	local hit_position = ray and ray.position
	if not (hit_unit or hit_position) then 
		self:log("No unit found!")
		return
	end
	
	local is_world = hit_unit:in_slot(QuickChat.cast_slotmasks.world)
	local target_name
	local target_category
	local is_character
	local is_dead
	local sound_id
	local anim_id
	local normal = ray.normal
	local unit
	
	--search for valid target objects:
	if contextual then 
		
		--search for character (enemy, civilian, friendly ai)
		local function find_character(_unit,recursive_search)
			local dmg_extension = _unit.character_damage and _unit:character_damage()
			is_dead = dmg_extension and dmg_extension:dead()
			if dmg_extension and not is_dead then 
				
				local enemy_team = true
				local is_civilian = true
				local is_teammate = true
				if enemy_team then 
					params = self.waypoint_parameters.attack
				elseif is_civilian then 
				elseif is_teammate then 
				end
				
				return _unit
			elseif recursive_search and _unit:in_slot(8) and alive(_unit:parent()) then 
				--if the raycast unit is the shield equipment held by a Shield enemy,
				--find that Shield enemy instead of the shield equipment itself
				return find_character(_unit:parent(),false)
			end
		end

		unit = find_character(hit_unit,true) or unit
		
		
		--search for interactable objects
		local interaction_ext = hit_unit.interaction and hit_unit:interaction()
		if interaction_ext then 
			if not interaction_ext._disabled and interaction_ext._active then 
				unit = hit_unit or unit
				local interaction_tweak_id = interaction_ext.tweak_data
				local contextual_interaction_data = interaction_tweak_id and self.tweak_data.contextual_interactions[interaction_tweak_id]

				
				target_category = managers.localization:text("menu_ping_category_interactable")
				params = self.waypoint_parameters.interact
				if contextual_interaction_data then 
					local interaction_tweak_data = tweak_data.interaction[interaction_tweak_id]
					sound_id = contextual_interaction_data.sound_id
					anim_id = contextual_interaction_data.anim_id
					
					target_name = (interaction_tweak_data.text_id and managers.localization:text(interaction_tweak_data.text_id)) or (contextual_interaction_data.target_name and managers.localization:text(contextual_interaction_data.target_name)) or target_name
					target_category = contextual_interaction_data.target_category and managers.localization:text(contextual_interaction_data.target_category) or target_category
					
					if contextual_interaction_data.ping_type then
						params = self.tweak_data.waypoint_parameters[contextual_interaction_data.ping_type] or params
					end
				end
			end
		end
		
		if unit and unit:in_slot(self.cast_slotmasks.pickups) then 
			params = self.waypoint_parameters.pickups
		end
--		if unit and unit:base() and getmetatable(unit:base()) == Pickup then 
			--it's a pickup! pick it up!
			
--		end
		
		--autotarget/icon here
	elseif not hit_unit:in_slot(managers.slot._masks.world_geometry) then
		unit = hit_unit
	end
	
	local panel_params = {
		id = params.id,
		text = params.text,
		texture = params.texture,
		texture_rect = params.texture_rect,
		color = params.color,
		is_world = is_world
	}
	local icon_id = params.icon_id
	if icon_id then 
		local icon_type = params.icon_type
		if icon_type == 1 then 
			panel_params.texture,panel_params.texture_rect = tweak_data.hud_icons:get_icon_data(icon_id)
		elseif icon_type == 2 then 
			panel_params.texture = self.tweak_data.premade_icons[icon_id].texture
			panel_params.texture_rect = self.tweak_data.premade_icons[icon_id].texture_rect
		end
	end
	
	if unit then 
		local unit_key = unit:key()
		if unit:character_damage() then 
			if is_dead == nil then 
				is_dead = unit:character_damage():dead()
			end
			
			is_character = true
		end
		--if the ping raycast hits a valid unit (enemy, civilian, interactable, etc; ie, not world geometry),
		--synced remove any user pings on that unit
		for i=#self.active_waypoints[self.USER_ID],1,-1 do 
			local _waypoint_data = self.active_waypoints[self.USER_ID][i]
			if _waypoint_data and alive(_waypoint_data.unit) and _waypoint_data.unit:key() == unit_key then 
				self:RemoveWaypoint(self.USER_ID,i)
				--break --replace the marker
				return --or cancel entirely
			end
		end
		
		panel_params.unit = unit
	end
	panel_params.position = hit_position
	panel_params.is_character = is_character
	panel_params.light_enabled = true
	
	if params.sound_id and not sound_id then 
		if type(params.sound_id) == "table" then 
			sound_id = table.random(params.sound_id)
		elseif type(params.sound_id) == "string" then 
			sound_id = params.sound_id
		end
	end
	if sound_id then 
		self:PlayCriminalSound(sound_id,true)
	end
	if params.anim_id and not anim_id then 
		anim_id = params.anim_id
	end
	
	if anim_id then 
		self:PlayViewmodelAnimation(anim_id)
	end
	
	if false and params.effect then --not yet implemented
		local effect_position = Vector3()
		
		local parent_object_name = params.effect.parent_object_name
		local parent_object = parent_object and unit:get_object(Idstring(parent_object_name))
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
			DelayedCallbacks:Add("ping_effect_" .. tostring(unit:key()),effect_lifetime,function()
				if effect and effect ~= -1 then 
					World:effect_manager():kill(effect)
				end
			end)
		end
	end
	
	--create waypoint panel here
	--if timer is enabled (if modifier key is held), or if waypoint data forces timer, instigate timer?
	local output_data =	self:AddWaypoint(panel_params)
	
	self:log("You pinged " .. tostring(target_category) .. " - " .. tostring(target_name))
	
	if output_data then
		self.num_waypoints = self.num_waypoints + 1 --increment unique waypoint num
		output_data.destroy_id = self.num_waypoints
		output_data.ping_type = ping_type
		output_data.unit = unit
		output_data.position = hit_position
		output_data.is_character = is_character
		output_data.is_dead = output_data.is_dead
		output_data.target_name = target_name
		output_data.target_category = target_category
		output_data.is_world = is_world
		output_data.normal = normal
		output_data.color = params.color
		output_data.owner_id64 = self.USER_ID
		output_data.beam_color = tweak_data.chat_colors[managers.network:session():local_peer():id()]
		
		if #self.active_waypoints[self.USER_ID] > self:GetMaxPingsPerPlayer() then 
			self:RemoveWaypoint(self.USER_ID,#self.active_waypoints[self.USER_ID])
		end
		
		self:RegisterWaypoint(output_data)
		
--		self:SyncWaypointToPeers(waypoint_data) --todo
	end
end
	
--create hud indicators with this waypoint data
function QuickChat:AddWaypoint(creation_data)
	local parent_panel = managers.hud._workspace:panel()
	if alive(parent_panel) then 
		--create panel for waypoint, and all the bits
		local waypoint_data = {}
		
		local bitmap_size = 24
		local panel = parent_panel:panel({
			name = creation_data.id,
			w = 200,
			h = 50
		})
		waypoint_data._panel = panel
		local bitmap = panel:bitmap({
			name = "bitmap",
			texture = creation_data.texture,
			texture_rect = creation_data.texture_rect,
			color = creation_data.color,
			w = bitmap_size,
			h = bitmap_size,
			layer = 2
		})
		bitmap:set_y((panel:h() - bitmap:h()) / 2)
		local outer_box = panel:rect({
			w = bitmap_size,
			h = bitmap_size,
			rotation = 45,
			alpha = 0.7,
			layer = -3
		})
		outer_box:set_center(bitmap:center())
		
		waypoint_data._bitmap = bitmap
		
		waypoint_data.x_offset = - bitmap_size / 2 --2
		
		waypoint_data._text = panel:text({
			name = "text",
			text = tostring(creation_data.text),
			align = "left",
			x = bitmap_size * 1.5,
	--		x = -100,
	--		y = -100,
			font = "fonts/font_medium_shadow_mf",
			font_size = 24,
			vertical = "center",
			alpha = 0.8,
			layer = 3,
			color = Color.white
		})
		
		local do_workspace = true
		if do_workspace then
			local w = 100
			local h = 800
			local world_w = w * 0.1
			local world_h = h * 0.1
			
			local start_pos = Vector3()
			if creation_data.is_world then 
				start_pos = creation_data.position or start_pos
			end
			
			local ws = self._gui:create_world_workspace(world_w,world_h,start_pos - Vector3(0,world_h/2,0),Vector3(world_w,0,0),Vector3(0,world_h,0))
			ws:set_billboard(Workspace.BILLBOARD_BOTH)
			ws:panel():rect({
				name = "debug",
				color = Color.red,
				alpha = 0.25
			})
			ws:panel():bitmap({
				name = "bitmap",
				w = w,
				h = h,
				texture = tweak_data.hud_icons.wp_arrow.texture,
				texture_rect = tweak_data.hud_icons.wp_arrow.texture_rect,
				color = creation_data.color
			})
			
			--[[
			local position_offset_x = 0
			local position_offset_y = 0
			local position_offset_z = 0
			local rot = managers.viewport:get_current_camera():rotation()
			local rot_nopitch = Rotation(rot:yaw(),0,rot:pitch())
			local position_offset = Vector3(position_offset_x,position_offset_y,0)
			mvec3_rot(position_offset,rot_nopitch)
			local hit_unit = creation_data.unit
			local attachment_obj = hit_unit:get_object(Idstring("Head")) or hit_unit:orientation_object()()
			local x_axis = rot:x():normalized() * world_w
			local oobb = attachment_obj:oobb
			local y_axis = rot:z():normalized() * world_h
			local top_left = oobb:center() + Vector3(0,0,position_offset_z) + position_offset - (x_axis / 2)
			ws:set_linked(world_w,world_h,attachment_obj,top_left,x_axis,y_axis)
			--]]
			local hit_unit = creation_data.unit
			if hit_unit and not creation_data.is_world then 
				local head_obj = hit_unit:get_object(Idstring("Head"))
				if creation_data.is_character and head_obj then 
					local attachment_obj = head_obj or hit_unit:orientation_object()
					local oobb = attachment_obj:oobb()
					ws:set_linked(world_w,world_h,attachment_obj,oobb:center() - Vector3(0,world_h/2,0),Vector3(world_w,0,0),Vector3(0,world_h,0))
				else
					local attachment_obj = hit_unit:orientation_object()
					ws:set_linked(world_w,world_h,attachment_obj,attachment_obj:position() - creation_data.position,Vector3(world_w,0,0),Vector3(0,world_h,0))
				end
			end
			waypoint_data._workspace = ws
		end
		
		
		if creation_data.light_enabled then 
			local light_texture = creation_data.light_texture or "units/lights/spot_light_projection_textures/spotprojection_11_flashlight_df" 
			local light = World:create_light("spot|specular|plane_projection", light_texture)
			waypoint_data._light = light
			light:set_position(creation_data.position + Vector3(0,0,0))
			light:set_color(Color.red or creation_data.color)
			light:set_spot_angle_end(90)
			light:set_far_range(10000)
			light:set_multiplier(2)
			light:set_rotation(Rotation(0,0,0))
			light:set_enable(true)
		end
		
		return waypoint_data
	else
		self:log("ERROR: AddWaypoint() failed- parent panel does not exist")
	end
	
	return false
end

function QuickChat:RemoveWaypoint(id64,index)
	local waypoint = self:UnregisterWaypoint(id64,index)
	if waypoint then 
		self:DestroyWaypoint(waypoint)
	end
end

--register user waypoint
function QuickChat:RegisterWaypoint(waypoint_data)
	table.insert(self.active_waypoints[self.USER_ID],1,waypoint_data)
end

function QuickChat:UnregisterWaypoint(id64,index)
	if id64 and index and self.active_waypoints[id64] and self.active_waypoints[id64][index] then 
		return table.remove(self.active_waypoints[id64],index)
	end
end

function QuickChat:DestroyWaypoint(waypoint_data)
	if waypoint_data._workspace then 
		self._gui:destroy_workspace(waypoint_data._workspace)
		waypoint_data._workspace = nil
	end
	if alive(waypoint_data._panel) then 
		
		waypoint_data._panel:parent():remove(waypoint_data._panel)
		waypoint_data._panel = nil
		
		waypoint_data._bitmap = nil
		waypoint_data._text = nil
	end
	
	if waypoint_data._light then 
		if waypoint_data._light ~= -1 then 
			World:delete_light(waypoint_data._light)
		end
		waypoint_data._light = nil
	end
	
end

function QuickChat:FadeoutDestroyWaypoint(waypoint_data)
	local function fadeout_func(o)
		local dt = coroutine.yield()
		over(self:GetWaypointFadeoutDuration(),function(progress)
			local n = 1 - progress
			o:set_alpha(n * n)
		end)
		self:DestroyWaypoint(waypoint_data)
	end
	
	if waypoint_data._panel then 
		waypoint_data._panel:animate(fadeout_func)
	end
end

function QuickChat:ReceiveWaypoint(peer,ping_data)
	local id64 = peer:user_id()
	self.active_waypoints[id64] = self.active_waypoints[id64] or {}
	
	if #self.active_waypoints[id64] >= self:GetMaxPingsPerPlayer() then 
		local old_waypoint = self:RemoveWaypoint(id64,#self.active_waypoints[id64])
		--fadeout waypoint, not instant removal
	end
	local waypoint_data = self:AddWaypoint(waypoint_data)
	if waypoint_data then 
		table.insert(self.active_waypoints[id64],1,waypoint_data)
	end
end

function QuickChat:GetWaypointById(id64,id)
	return self.active_waypoints[id64] and self.active_waypoints[id64][id]
end

function QuickChat:ClearAllWaypointsByPeer(id64)
	for i=#self.active_waypoints[id64],1,-1 do 
		local waypoint_data = table.remove(self.active_waypoints[id64],i)
		if waypoint_data then 
			self:DestroyWaypoint(waypoint_data)
		end
	end
end

function QuickChat:ClearAllWaypoints()
	for user_id,waypoints_list in pairs(self.active_waypoints) do 
		for i=#waypoints_list,1,-1 do 
			local waypoint_data = table.remove(waypoints_list,i)
			if waypoint_data then 
				self:DestroyWaypoint(waypoint_data)
			end
		end
	end
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
	
	return table.concat({
		message_id,
		custom_text,
		icon_type,
		icon_id,
		duration,
		target_type,
		target_id,
		position,
		destroy_id
	},"|")
end


--parse incoming data, return parsed data and an operation id
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
	},QuickChat.tweak_data.network_operation_ids.ADD
end

function QuickChat:SyncRemoveWaypoint_v1(message)
	local data = string.split(data,"|")
	local destroy_id = data[9] and tonumber(data[9])
	return {
		destroy_id = destroy_id
	},QuickChat.tweak_data.network_operation_ids.REMOVE
end

function QuickChat:Register_v1(message)
	return {
		version_id = message
	},QuickChat.tweak_data.network_operation_ids.REGISTER
end

--on network message received:
Hooks:Add("NetworkReceivedData", "NetworkReceivedData_QuickChat", function(sender, message_id, message)
	if managers.chat and managers.chat:is_peer_muted(sender) then
		--don't do anything because peer is muted
		--blocked. unfollowed. reported.
	else
		if message_id and QuickChat._network_data.sync_functions_by_name[message_id] then 
			local func_name = QuickChat._network_data.sync_functions_by_name[message_id]
			if func_name and type(QuickChat[func_name]) == "function" then 
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
	
	MenuCallbackHandler.callback_quickchat_setting_max_pings_per_player = function(self,item) --not yet implemented
		local value = tonumber(item:value())
		for user_id,waypoints_list in pairs(QuickChat.active_waypoints) do 
			if value < #QuickChat.active_waypoints then
				for i=#waypoints_list,#waypoints_list-value,-1 do 
					QuickChat:RemoveWaypoint(user_id,i)
				end
			end
		end
		
	end
	
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


	-- Localization (if BeardLib is installed, defers to BeardLib Localization Module) --
Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_QuickChat", function( loc )
	if not BeardLib then 
		loc:load_localization_file( QuickChat._localization_path .. "english.txt")
	end
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