--[[ i have started, stopped, made working prototypes for, scrapped, and restarted this mod no less than 7 times at various points in my time modding this game

	dofile("mods/PD2-QuickChat/lua/hooks/menumanager.lua")

	
todo:
	- highlight selected waypoint
	show distance option
	-custom table.concat implementation to allow empty strings of length zero
	--remove waypoints by vector dot within x deg
	--register to peers on connected
		- after register and load-in, inform local user of other users who are using ping menu (for case-specific compatibility between versions)
		- sync existing waypoints to mid-game joins (needs hook)
	- local limit should apply to other players' waypoints	
	rewrite sync code version handling (use message id instead to handle both version number and operation type) 
	- "killfeed" type extra flatscreen hud element (moveable) to show recent pings
		- or, show feed in chat 
	-resolve auto-removing waypoints of other clients:
		- eg. killing a unit removes the waypoint automatically if the waypoint is a character waypoint
		- are waypoints truly and completely client-authoritative?
	-implement timer
	- fix slotmask raycasts to allow pinging keycards, etc.
	-resolve wall-ping behavior
		glowing circle for positional markers (spotlight + circle graphic aligned against normal dir; repurpose waypoint)
	hide waypoints when not in game
	"static" waypoints are created as an offset from the unit, for world collision waypoints
	vertical waypoint offset (by screen instead of by world)
	offscreen waypoint position updating
	-optional "[You] pinged [object]" message in local chat
	-voice command cooldown
lower priority todo: 
	allow contextual "responding" when pinging others' waypoints; eg. pinging a keycard that someone else has pinged will say "dibs"; appears in chat or feed
	prevent ADS when exiting radial menu with rightclick
	--separate table to handle fade-remove waypoints
	--radial menu
		--custom radial menu graphics
		--adjust position of text
		--adjust size
	case-specific ping types for contextual pings
		- deployables: show amount remaining?
	--closed captions compatibility?
	--customization
		--edit action radials
		--add and custom keybind N number of action radials in menu?
	--menu to manually clear waypoints from any or all player(s)
	--hold button to switch to n-second timer?
	--timer icon should be separate from normal icon
	--slow fade remove while still updating positions
	- json formatted custom radials, addon style
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
cmd_stop

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
	1. [String] waypoint_id: Unique identifier for this waypoint. Owner-authoritative, should be unique, for syncing removal from owner. Is a stringified Integer, starting at 1 and incrementing upwards for each new waypoint.
		If this is not unique, waypoints may linger and be unable to be removed by the owner. 
		Local user should be able to remedy this by manually clearing stale waypoints.
	2. [String] text_id: Text identifier for waypoint label. Corresponds to a localized string id in QuickChat.tweak_data.premade_text_messages.
	3. [String] custom_text: Custom waypoint label. Not localized, from owner. If present and allowed, this overrides the text_id.
	4. [Integer] icon_type: Represents which "library" to retrieve icon data from:
		= 1: from tweak_data.hud_icons, using get_icon_data(icon_id)
		= 2: from QuickChat.tweak_data.premade_icons[icon_id]
	5. [String] icon_id: The key of this icon, as corresponding to either icon "library" as listed above.
	6. [Float] end_t: The time (Application:time() value) at which this waypoint will be automatically destroyed. Can be "nil".
	7. [Boolean] show_timer: If true, and if end_t is valid, shows the amount of time remaining in the waypoint text. Can be "nil".
	8. [Vector3] position: The coordinates of this waypoint in the world.
	9. [Integer] uid: A unique identifier for this unit, given by Unit:id(), which is synced across clients by the game engine. Can be "nil" if nonexistent.
	10. [Boolean] is_character: Represents whether or not the given unit is a character with the valid damage extension character_damage(). (Enemy, civilian, joker/hired help, teammate ai, player)
	11. [Boolean] is_world: Represents whether this waypoint is a "static" world waypoint. In this case, the waypoint will not update its position for any of its indicators (panel, workspace, spotlight)
	12. [Boolean] is_dead: Represents whether the given unit is dead, which will consequently require a different set of search parameters to find the unit by the given uid.
	
	
	local viewport_cam = managers.viewport:get_current_camera()
	local cam_pos = viewport_cam:position()
	local cam_aim = viewport_cam:rotation():y()
	local to_pos = (cam_aim * QuickChat.tweak_data.max_raycast_distance) + cam_pos
	
	local ray = World:raycast("ray",cam_pos,to_pos,"slot_mask",QuickChat.cast_slotmasks.generic + QuickChat.cast_slotmasks.generic)
	logall(ray)
	local is_geometry = ray.unit:in_slot(managers.slot:get_mask("world_geometry"))
	
	
	---
	
	local wp = QuickChat.active_waypoints.local_user[1]
	wp._light:set_spot_angle_end(30)
	wp._light:set_far_range(400)	
	
	wp._light:set_rotation((0,180,0))
	
	return wp._light:set_falloff_exponent(0)
	
	wp._light:set_ambient_cube_side(1,Color.red)
	wp._light:set_ambient_cube_side(2,Color.green)
	wp._light:set_ambient_cube_side(3,Color.blue)
	wp._light:set_ambient_cube_side(4,Color(1,1,0))
	wp._light:set_ambient_cube_side(5,Color(1,0,1))
	wp._light:set_ambient_cube_side(6,Color(0,1,1))
	wp._light:set_ambient_cube_side(0,Color(1,0.5,0))
	
	
	
	wp._light:set_rotation(Rotation(0,45,0))
	return wp._light:rotation()
--	wp._light:set_rotation(Rotation(0,0,0))
--	wp._light:set_position(managers.player:local_player():position())
	
	logall(wp)
	
	
	local wp = QuickChat.active_waypoints.local_user[1]
	wp._light:set_rotation(Rotation(0,0,90))
	
	
	return wp._light:position()
	
	
	wp._light:set_spot_angle_end(90)
	wp._light:set_far_range(10000)
	
	---
	
	
	local texture = "units/lights/spot_light_projection_textures/spotprojection_11_flashlight_df" or "guis/textures/pd2/hud_radialbg"
	mynewlight = World:create_light("spot|specular|plane_projection", texture)
	mynewlight:set_color(Color.red)
	mynewlight:set_spot_angle_end(60)
	mynewlight:set_far_range(1000)
	mynewlight:set_multiplier(2)
	mynewlight:set_rotation(Rotation(0,0,0))
	mynewlight:set_enable(true)
--	mynewlight:link(self._a_flashlight_obj)
	
	mynewlight:set_position(managers.player:local_player():position() + Vector3(0,0,100))
	
	
	
	
	
	
		local effect_path = "effects/particles/weapons/flashlight/flashlight_multicolor"
		mylighteffect = World:effect_manager():spawn({
			effect = Idstring(mylighteffect)
		})
		if mylighteffect and mylighteffect ~= -1 then 
			local r_ids = Idstring("red")
			local g_ids = Idstring("green")
			local b_ids = Idstring("blue")
			local color = Color.red
			local opacity_ids = Idstring("opacity")
			local opacity = 255
			World:effect_manager():set_simulator_var_float(mylighteffect, r_ids, r_ids, opacity_ids, color.r * opacity)
			World:effect_manager():set_simulator_var_float(mylighteffect, g_ids, g_ids, opacity_ids, color.g * opacity)
			World:effect_manager():set_simulator_var_float(mylighteffect, b_ids, b_ids, opacity_ids, color.b * opacity)
			mylighteffect:set_position(managers.player:local_player():position() + Vector3(0,0,100))
		else
			mylighteffect = nil
		end
		
		
		World:effect_manager():kill(self._light_effect)
	
	
lighttexture="guis/textures/pd2/hud_shield"
function cycle_pinglight()
	local lights = {		"units/lights/spot_light_projection_textures/spotprojection_05_flashlight_df",
		"units/lights/spot_light_projection_textures/spotprojection_12_flashlight_df",
		"units/lights/spot_light_projection_textures/spotprojection_16_flashlight_df",
		"units/lights/spot_light_projection_textures/spotprojection_06_downlight_df",
		"units/lights/spot_light_projection_textures/spotprojection_10_flower_df",
		"units/lights/spot_light_projection_textures/spotprojection_08_flashlight_df",
		"units/lights/spot_light_projection_textures/spotprojection_08_spot_df",
		"units/lights/spot_light_projection_textures/spotprojection_07_round_df",
	}
	lighttextureindex = (lighttextureindex + 1) % #lights
	lighttexture = lights[lighttextureindex] or lighttextureindex
	OffyLib:c_log("New texture: " .. tostring(lighttexture) .. " : " .. tostring(lighttextureindex) .. "/" ..tostring(#lights))
end
	
	
	
	
--]]
--wp_escort

local mrot_y = mrotation.y
local mvec3_rot = mvector3.rotate_with
local mvec3_nrm = mvector3.normalize
local mvec3_dot = mvector3.dot
local mvec3_copy = mvector3.copy
local mvec3_add = mvector3.add
local mvec3_set = mvector3.set

	-- Init mod values --
QuickChat = QuickChat or {}
QuickChat._mod_path = ModQuickChat and ModQuickChat.GetPath and ModQuickChat:GetPath() or ModPath
QuickChat._localization_path = QuickChat._mod_path .. "localization/"
QuickChat._assets_path = QuickChat._mod_path .. "assets/"
QuickChat._menu_path = QuickChat._mod_path .. "menu/"
QuickChat._save_path = SavePath .. "quickchat_settings.json"
QuickChat._waypoints_save_path = SavePath .. "quickchat_waypoints.json"
QuickChat._network_data = {
	sync_functions_by_name = { --parsers by version id
		["QuickChat_v1_Register"] = "Register_v1",
		["QuickChat_v1_Add"] = "SyncAddWaypoint_v1",
		["QuickChat_v1_Remove"] = "SyncRemoveWaypoint_v1"
	},
	sync_functions_by_version = {
		["1"] = {
			add = "QuickChat_v1_Add",
			remove = "QuickChat_v1_Remove",
			register = "QuickChat_v1_Register"
		}
	},
	current_sync_ids = {
		add = "QuickChat_v1_Add",
		remove = "QuickChat_v1_Remove",
		register = "QuickChat_v1_Register"
	}
}

QuickChat.default_settings = {
	debug_log_enabled = true,
	max_pings_per_player = 3,
	waypoint_fadeout_duration = 1,
	waypoint_spotlight_enabled = true,
	allow_custom_text = true,
	ping_keybind = "mouse 4"
}
QuickChat.settings = QuickChat.settings or table.deep_map_copy(QuickChat.default_settings)

QuickChat.radial_menu_object_template = {
	name = "PingMenu",
	radius = 600,
	deadzone = 100,
	items = {},
	allow_camera_look = false,
	block_all_input = false,
	allow_keyboard_input = true,
	center_text = {
		name =  "CENTER_TEXT",
		text = "",
		layer = 1,
		font_size = 32,
		align = "center",
		vertical = "top",
		y = 276,
		font = tweak_data.hud.medium_font,
		color = Color.white
	},
	bg = {
		name = "BG",
		texture = "guis/textures/pd2/quickchat/radial_bg",
		valign = "grow",
		halign = "grow",
		layer = 1,
		blend_mode = "normal",
		color = Color(0,0,0),
		alpha = 0.3,
		w = 600,
		h = 600
	}
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
--	callback = callback(QuickChat,QuickChat,"create_ping","Ping_LookieHere"), --example of what the final callback looks like 
	show_text = false,
	stay_open = false
}
QuickChat.radial_menu_data = {} --for reference

QuickChat.USER_ID = QuickChat.USER_ID or "local_user"

QuickChat._dependencies = {
	radialmousemenu = {
		check_has_dependency = function()
			return _G.RadialMouseMenu and true or false
		end,
		name_id = "menu_dependency_radialmousemenu_title",
		desc_id = "menu_dependency_radialmousemenu_desc",
		link = "https://modworkshop.net/mod/27225"
	},
	holdthekey = {
		check_has_dependency = function()
			return _G.HoldTheKey and true or false
		end,
		name_id = "menu_dependency_holdthekey_title",
		desc_id = "menu_dependency_holdthekey_desc",
		link = "https://modworkshop.net/mod/22253"
	}
}

QuickChat.tweak_data = QuickChat.tweak_data or {
	keybind_ids = {
		ping_menu = "pingwaypoint_keybind_ping"
	},
	network_operation_ids = {
		REGISTER = 1,
		ADD = 2,
		REMOVE = 3
	}, 
	beam = {
		height = 2000, --centimeters
		radius = 1, --centimeters
		alpha = 0.25
	},
	spotlight = {
		offset_position = Vector3(0,0,100),
		angle = 45,
		range = 350,
		mul_index = 2,
		texture = "units/lights/spot_light_projection_textures/spotprojection_08_spot_df"
	},
	gui_bitmap = {
		size = 24,
		alpha = 1,
		layer = 2
	},
	gui_text = {
		font = "fonts/font_medium_shadow_mf",
		font_size = 24,
		alpha = 0.8,
		layer = 3,
		color = Color.white
	},
	gui_workspace = {
		w = 400,
		h = 800,
		world_scale = 0.1
	},
	gui_rect = {
		rotation = 45,
		alpha = 0.7,
		layer = -1
	},
	gui_panel = {
		w = 200,
		h = 50
	},
	gui_arrow = {
		icon_id = "wp_arrow",
		w = 24,
		h = 24,
		alpha = 1,
		layer = 4
	},
	waypoint_icon_vertical_offset = -50, --pixels
	default_waypoints = {
		generic = {
			id = "generic",
			text_id = "text_look",
			color = Color(1,1,1),
			icon_id = "wp_standard",
			icon_type = 1, --1 = hudiconstweakdata, 2 = premade
			effect = "default",
			sound_id = "g15",
			anim_id = "cmd_point",
			create_ping = true,
			contextual = true,
			duration = nil,
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
		look = {
			id = "look",
			text_id = "text_look",
			color = Color(1,1,1),
			icon_id = "wp_standard",
			icon_type = 1,
			effect = "default",
			sound_id = "g15",
			anim_id = "cmd_point",
			create_ping = true,
			contextual = false,
			duration = nil,
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
		defend = {
			id = "defend",
			text_id = "text_defend",
			color = Color(1,1,1),
			icon_id = "pd2_defend",
			icon_type = 1,
			effect = "default",
			sound_id = "g16", --keep defending!
			anim_id = "cmd_stop",
			create_ping = true,
			contextual = false,
			duration = nil,
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
		interact = {
			id = "interact",
			color = Color(1,1,1),
			text_id = "text_interact",
			icon_id = "pd2_generic_interact",
			icon_type = 1,
			effect = "default",
			sound_id = "v44",
			anim_id = "cmd_point",
			create_ping = true,
			contextual = false,
			duration = nil,
			show_distance = true,
			show_timer = false,
			use_timer = false,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = false,
				pickups = false,
				deployables = false
			}
		},
		pickup = {
			id = "pickup",
			color = Color(1,1,1),
			text_id = "text_pickup",
			icon_id = "icon_pickup",
			icon_type = 2,
			effect = "default",
			sound_id = "v04", --"found it, it's here"
			anim_id = "cmd_point",
			create_ping = true,
			contextual = false,
			duration = nil,
			show_distance = true,
			show_timer = false,
			use_timer = false,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = false,
				pickups = true,
				deployables = false
			}
		},
		go = {
			id = "go",
			color = Color(1,1,1),
			text_id = "text_go",
			icon_id = "pd2_goto", --or pd2_escape
			icon_type = 1,
			effect = "default",
			sound_id = "g13", --"let's go"
			anim_id = "cmd_gogo",
			create_ping = true,
			contextual = false,
			duration = nil,
			show_distance = true,
			show_timer = false,
			use_timer = false,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = false,
				pickups = true,
				deployables = false
			}
		},
		attack = {
			id = "attack",
			color = Color(1,1,1),
			text_id = "text_attack",
			icon_id = "pd2_kill",
			icon_type = 1,
			effect = "default",
			sound_id = "g23", --"shoot em!" or "v18" for "wipe em out/clear the room"
			anim_id = "cmd_point",
			create_ping = true,
			contextual = false,
			duration = nil,
			show_distance = true,
			show_timer = false,
			use_timer = false,
			cast_targets = {
				enemies = true,
				civilians = true,
				friendlies = false,
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
		text_look = "menu_ping_look_label", --look at this thing!
		text_pickup = "menu_ping_pickup_label", --get this thing!
		text_interact = "menu_ping_interact_label", --use this thing!
		text_attack = "menu_ping_attack_label", --attack this thing!
		text_defend = "menu_ping_defend_label", --defend this thing!
		text_go = "menu_ping_go_label", --go to this thing!
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
		all = nil, --special; concatenated slotmask of all others
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
		[id64 or "local_user"] = {
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

function QuickChat:IsSpotlightEnabled()
	return self.settings.waypoint_spotlight_enabled
end

-- only use this for comparing, NOT to use as an index, since it can be zero/inf
function QuickChat:GetMaxPingsPerPlayer()
	local pings_max = self.settings.max_pings_per_player
	if pings_max == 0 then 
		return math.huge
	else
		return math.ceil(pings_max)
	end
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

function QuickChat.string_to_bool(str)
	if str == "true" then 
		return true
	elseif str == "false" then 
		return false
	else
		return nil
	end
end

function QuickChat:PopulateSlotmaskData()
		--populate cast slotmasks
	for k,v in pairs(self.tweak_data.cast_slotmasks) do 
		if type(v) == "string" then
			local slotmask = managers.slot:get_mask(v)
			self.cast_slotmasks[k] = slotmask
			
			self.cast_slotmasks.all = self.cast_slotmasks.all or slotmask
			self.cast_slotmasks.all = self.cast_slotmasks.all + slotmask
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
			self.cast_slotmasks.all = self.cast_slotmasks.all or slotmask
			self.cast_slotmasks.all = self.cast_slotmasks.all + slotmask
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
			text_id = v.text_id,
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
			duration = v.duration,
			show_distance = v.show_distance,
			show_timer = v.show_timer,
			use_timer = v.use_timer,
			anim_id = v.anim_id
		}
	end
end

function QuickChat:PopulateUserWaypointData()
	--process user-made waypoints (todo)
end

function QuickChat:CreateRadialMenus()
	--generate radial menu data (creation comes later)
	local radial_menu_data = table.deep_map_copy(self.radial_menu_object_template)
	
	table.insert(radial_menu_data.items,self:GenerateRadialItem("look"))
	table.insert(radial_menu_data.items,self:GenerateRadialItem("attack"))
	table.insert(radial_menu_data.items,self:GenerateRadialItem("pickup"))
	table.insert(radial_menu_data.items,self:GenerateRadialItem("go"))
	table.insert(radial_menu_data.items,self:GenerateRadialItem("defend"))
	table.insert(radial_menu_data.items,self:GenerateRadialItem("interact"))
	
	self.radial_menu_data = radial_menu_data
end

function QuickChat:GenerateRadialItem(id)
	local template_data = self.waypoint_parameters[id]
	local new_item 
	if template_data then 
		new_item = table.deep_map_copy(self.radial_menu_item_template)
		new_item.text = template_data.text
		local texture,texture_rect
		local icon_id,icon_type = template_data.icon_id,template_data.icon_type
		if icon_id then 
			if icon_type == 1 then 
				texture,texture_rect = tweak_data.hud_icons:get_icon_data(icon_id)
			elseif icon_type == 2 then 
				local icon_tweakdata = self.tweak_data.premade_icons[icon_id]
				if icon_tweakdata then 
					texture = icon_tweakdata.texture
					texture_rect = icon_tweakdata.texture_rect
				end
			end
		end
		new_item.icon = {
			texture = texture,
			texture_rect = texture_rect,
			w = template_data.w,
			h = template_data.h,
			color = template_data.color
		}
		new_item.callback = callback(self,self,"CreatePing",id)
	end
	return new_item
end

function QuickChat:SetRadialMenu(id,menu)
	self.active_radial_menus[id] = {
		menu = menu,
		input_cache = nil
	}
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
	
	menu.populate_items = function(self)
		self:reset_items(true)
		
		local num_items = math.max(#self._items,1)
		for k,data in ipairs(self._items) do
			local text = data.text or ""
			local name = "item_" .. k
			local ho = self._hud:h() / 2
			local wo = self._hud:w() / 2
			local new_segment = self._hud:panel({
				name = name .. "_PANEL",
				layer = 2,
				w = self._size,
				h = self._size
			})
			new_segment:set_center(wo,ho)
			data._panel = new_segment
			
			local angle = (360 * ((k - 1) / num_items) - 90) % 360

			local body = data.bitmap or {
				layer = 1,
				alpha = 0.3,
				texture = "guis/textures/pd2/quickchat/radial_selector",
				w = self._size / 2,
				h = self._size / 2
			}
			body.name = name .. "_TEXTURE"
			
			body.render_template = "VertexColorTexturedRadial"
			body.color = Color(1/num_items,1,1)
			body.rotation = angle + 90 - (180/num_items)
			local segment_texture = new_segment:bitmap(body)
			segment_texture:set_center(self._size / 2,self._size / 2)
			data._body = segment_texture

			local icon = data.icon or {
				layer = 3,
				visible = false,
				color = tweak_data.chat_colors[1 + (k % #tweak_data.chat_colors)] or Color.white
			}
			icon.name = name .. "_ICON"
			icon.w = icon.w or 24
			icon.h = icon.h or 24
			
			local x = (math.cos(angle) * (self._size * 0.314))
			local y = ((math.sin(angle) * (self._size * 0.314)) + - (icon.h / 2)) + (self._size / 2)
			icon.x = x + (self._size / 2) -- -(icon.w / 2)
			icon.y = y
			icon.halign = "center"
			icon.valign = "center"
			
			
			local segment_icon = new_segment:bitmap(icon)
			segment_icon:set_center(icon.x,icon.y)
			data._icon = segment_icon
			
			local text_panel = data.text_panel or { 
				name = name .. "_TEXT_PANEL",
				text = text,
				x = x,
				y = y + 12,
				align = "center",
				font = tweak_data.hud.medium_font,
				font_size = 12,
				alpha = 1,
				layer = 1,
				color = Color.white
			}
			text_panel.visible = data.show_text or false
			local segment_text_panel = new_segment:text(text_panel)
			data._text_panel = segment_text_panel

			
			
			self._selector:set_color(Color(1/num_items,1,1))
		end	
		self._init_items_done = true
	end
	
	menu:reset_items()
	
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
	for menu_id,data in pairs(self.active_radial_menus) do
		local keybind_id = self.tweak_data.keybind_ids[menu_id]
		--return HoldTheKey:Get_Mod_Keybind("pingwaypoint_keybind_ping")
--		local held = HoldTheKey:Keybind_Held(keybind_id)
		local held = HoldTheKey:Key_Held(self.settings.ping_keybind or "mouse 2")
		local input_cache = data.input_cache
		
		data.input_cache = held --update cached key state now so that we can break at will
		local menu = data.menu
		if menu:active() then 
			if input_cache and not held then
				menu:Hide(nil,true)
				break
			end
		else
			if held and not input_cache then
				menu:Show()
				break
			end
		end
	end
end

function QuickChat:UpdateWaypoints(t,dt)

	local camera = managers.viewport:get_current_camera()
	if not camera then 
		self._selected_ping = nil
		return
	end
	local cam_pos = camera:position()
	local cam_rot = camera:rotation()
	local cam_dir = cam_rot:y():normalized()
	local cam_dir_nrm = cam_dir:normalized()
	
	local workspace = managers.hud._workspace
	local parent_panel = workspace:panel()
	local parent_center_x,parent_center_y = parent_panel:center()
	
	local best_waypoint_dot = 0.998
	local best_waypoint_id,best_waypoint_user_id
	
	local arrow_w = self.tweak_data.gui_arrow.w
	local arrow_h = self.tweak_data.gui_arrow.h
	
	for user_id,waypoints_list in pairs(self.active_waypoints) do 
		for i=#waypoints_list,1,-1 do 
			local queued_remove
			
			local waypoint_data = waypoints_list[i]
			local waypoint_id = waypoint_data.waypoint_id
			local color = waypoint_data.color or Color.white
			local beam_color = waypoint_data.beam_color or tweak_data.chat_colors[5]
			local unit = waypoint_data.unit
			local ping_type = waypoint_data.ping_type
			local panel = waypoint_data._panel
			local text = waypoint_data._text
			local bitmap = waypoint_data._bitmap
			local arrow = waypoint_data._arrow
			local x_offset = waypoint_data.x_offset or 0
			local spotlight = waypoint_data._spotlight
			local is_character = waypoint_data.is_character
			local is_world = waypoint_data.is_world
			local is_dead = waypoint_data.is_dead
			local unit_alive = unit and alive(unit)
			--check for timeout
			if waypoint_data.end_t then 
				if t > waypoint_data.end_t then 
					queued_remove = true
				end
			end

			local panel_w,panel_h = panel:size()
			
			if not queued_remove then 
				--check for dead
				
				--update position on screen
				
				local target_position = waypoint_data.position
				if is_character and not is_dead then 
					if unit_alive then 
						if unit:character_damage():dead() and not managers.groupai:state():whisper_mode() then 
							queued_remove = true
						end
					else
						queued_remove = true
					end
				end
				if not is_world then
					if unit_alive then 
						if not queued_remove then 
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
					end
					
					if spotlight then 
					--don't update light position if static
						local light_position = target_position + Vector3(0,0,150)
						spotlight:set_position(light_position)
	--					Draw:brush(Color.white):sphere(light_position,10)
	--					local r = light:rotation()
	--					light:set_rotation(Rotation(r:yaw(),r:pitch() + (dt * 360),r:roll()))
					end
				end
				
				
				
--				local from_pos,to_pos,pos
				if not queued_remove then 
					if target_position then 
						local orig_position = mvec3_copy(target_position)
						
					--draw beam
						Draw:brush(beam_color:with_alpha(self.tweak_data.beam.alpha)):cone(orig_position + Vector3(0,0,self.tweak_data.beam.height),orig_position,self.tweak_data.beam.radius)
						 
						
--						local waypoint_position = target_position + Vector3(0,0,400)
						local pos = workspace:world_to_screen(camera,target_position)
--						waypoint_data.panel_position = waypoint_data.panel_position or mvec3_copy(pos)
						local dir_to = target_position - cam_pos
						local dir_to_nrm = dir_to:normalized()
						local dot = mvector3.dot(cam_dir_nrm,dir_to_nrm)
						
						if dot > best_waypoint_dot then 
							best_waypoint_dot = dot
							best_waypoint_id = waypoint_id
							best_waypoint_user_id = user_id
						end
						
						
--						local screen_pos = mvector3.copy(pos)
					
						
--						Console:SetTrackerValue("trackera",string.format("%0.4f",dot))
						
						local y_offset = 24
						if dot < 0 or parent_panel:outside(pos.x,pos.y) then 
						--[[
							waypoint_data.offscreen_timer = waypoint_data.offscreen_timer or 0
							waypoint_data.offscreen_timer = math.clamp(waypoint_data.offscreen_timer + dt,0,1)
							
							waypoint_data.onscreen_timer = nil
--							Console:SetTrackerValue("trackerb","outside " .. string.format("%0.2f,%0.2f",pos.x,pos.y))
							mvector3.set(waypoint_data.panel_position, math.bezier({
								waypoint_data.panel_position,
								waypoint_data.panel_position,
								pos,
								pos
							}, waypoint_data.offscreen_timer))
							--]]
							
							local screen_dir = Vector3(pos.x - parent_center_x,pos.y - parent_center_y,0)
--							Console:SetTrackerValue("trackere","angle " .. string.format("%0.2f,%0.2f",screen_dir.x,screen_dir.y))
							mvec3_nrm(screen_dir)
							
							panel:set_position(screen_dir.x,screen_dir.y)
							--[[
							pos.y = pos.y + self.tweak_data.waypoint_icon_vertical_offset
							local panel_w,panel_h = panel:size()
							if screen_dir.x < 0 then 
								panel:set_left(math.max(0,pos.x) + x_offset)
							else
								panel:set_right(parent_panel:w() + x_offset)
							end
							if screen_dir.y < 0 then 
								panel:set_top(math.max(y_offset,pos.y))
							else
								
							end
							
							
								if pos.x > parent_panel:w() - panel_w then 
								else
								end
								
								if pos.y > parent_panel:h() - panel_h then 
									panel:set_bottom(parent_panel:h() - y_offset)
								else
								end
							else
--								panel:set_right(parent_panel:w())
							end
							
							if screen_dir.y < 0 and screen_dir.y < 0 then 
--								panel:set_top(0)
							else
--								panel:set_bottom(parent_panel:h())
							end
							--]]
							if screen_dir.x < 0 then 
								panel:set_left(x_offset)
							else
								panel:set_right(parent_panel:w() + x_offset)
							end
							
--							Console:SetTrackerValue("trackerd","angle nrm " .. string.format("%0.2f,%0.2f",screen_dir.x,screen_dir.y))
							
--							Console:SetTrackerValue("trackerc","xy " .. string.format("%0.2f,%0.2f",panel_x,panel_y))
--							panel:set_position(panel_x,panel_y)

							--show arrow
							
							local arrow_angle = math.X:angle(screen_dir) * math.sign(screen_dir.y)
							arrow:set_rotation(arrow_angle)
							local arrow_center_x,arrow_center_y = bitmap:center()
							arrow:set_center(arrow_center_x + (arrow_w * screen_dir.x),arrow_center_y + (arrow_h * screen_dir.y))
							arrow:show()
							
						else
						--[[
							waypoint_data.onscreen_timer = waypoint_data.onscreen_timer or 0
							waypoint_data.onscreen_timer = math.clamp(waypoint_data.onscreen_timer + dt,0,1)
							waypoint_data.offscreen_timer = nil
						
							
							mvector3.set(waypoint_data.panel_position, math.bezier({
								waypoint_data.panel_position,
								waypoint_data.panel_position,
								pos,
								pos
							}, 1 - waypoint_data.onscreen_timer))
--]]
						--[[
							pos.y = pos.y + self.tweak_data.waypoint_icon_vertical_offset
							local panel_w,panel_h = panel:size()
							--]]
							
							
--							Console:SetTrackerValue("trackerb","inside")
							arrow:hide()
							
							if dot > 0.99 then
								local alpha = math.clamp((1 - dot) / 0.01, 0.4, 0.8)
								text:set_alpha(alpha)
							end
							
							if pos.x > parent_panel:w() - panel_w then 
								panel:set_right(parent_panel:w() + x_offset)
							else
								panel:set_left(math.max(0,pos.x) + x_offset)
							end
						end
--						panel:set_center(waypoint_data.panel_position.x,waypoint_data.panel_position.y)
						
						if pos.y > parent_panel:h() - panel_h then 
							panel:set_bottom(parent_panel:h() - y_offset)
						else
							panel:set_top(math.max(y_offset,pos.y))
						end
						--[[
						
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
						
						--]]
					else
						self:log("ERROR: No target position found for waypoint id " .. tostring(waypoint_data.waypoint_id))
					end
				
				end
			end
			
			if queued_remove then 
				self:RemoveWaypoint(user_id,i)
			end
			if best_waypoint_id then
				self._selected_ping = {
					user_id = best_waypoint_user_id,
					waypoint_id = best_waypoint_id
				}
			else
				self._selected_ping = nil
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

function QuickChat:ShouldAllowSyncCustomText()
	return self.settings.allow_custom_text
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
	
	
	local create_ping = params.create_ping

--played locally; sync handled separately
	local sound_id
	local anim_id
	
	if not create_ping then 
		sound_id = params.sound_id
		anim_id = params.anim_id
		
		--perform local actions (viewmodel redirect, voiceline)
		if sound_id then 
			if type(sound_id) == "table" then 
				sound_id = table.random(sound_id)
			elseif type(params.sound_id) == "string" then 
				--sound_id should be a string
			end
		end
		if sound_id then 
			self:PlayCriminalSound(sound_id,true)
		end
		
		if anim_id then 
			self:PlayViewmodelAnimation(anim_id)
		end
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
	
	local ray = World:raycast("ray",cam_pos,to_pos,"slot_mask",params.slotmask + self.cast_slotmasks.world)
	local hit_unit = ray and ray.unit
	local hit_position = ray and ray.position
	if not (hit_unit or hit_position) then 
		self:log("No unit found!")
		return
	end
	
	local user_id = self.USER_ID --"local_user"
	local contextual = params.contextual
	local normal = ray.normal --not used yet
	local interaction_tweak_id
	local is_interactable = false
--used for HUD feed
	local target_name
	local target_category
	
	
	
	--creation parameters:
	local waypoint_id = self.num_waypoints + 1
	local icon_id
	local icon_type
	local text_id
	local custom_text
	local color
	local duration
	local is_world = hit_unit:in_slot(QuickChat.cast_slotmasks.world)
	local is_character = false
	local is_dead = false
	local light_enabled = self:IsSpotlightEnabled()
	local workspace_enabled = false
	local unit
	
	
	if not is_world then 
		unit = hit_unit
	end
	
	if unit then
		if unit.character_damage and unit:character_damage() then

			local dmg_extension = unit:character_damage()
			is_character = true
			is_dead = dmg_extension:dead()
			
		elseif continue and unit:in_slot(8) and alive(unit:parent()) then 
			--if the raycast unit is the shield equipment held by a Shield enemy,
			--find that Shield enemy instead of the shield equipment itself

			local dmg_extension = parent.character_damage and parent:character_damage()
			is_character = true
			is_dead = dmg_extension:dead()
		end
		--todo check team (civilian, enemy, joker/hired help, teammate ai, player)
	end
	
	if unit then 
		--if the ping raycast hits a valid unit (enemy, civilian, interactable, etc; ie, not world geometry),
		--synced remove any user pings on that unit
		local unit_key = unit:key()
		for i=#self.active_waypoints[user_id],1,-1 do 
			local _waypoint_data = self.active_waypoints[user_id][i]
			if _waypoint_data and alive(_waypoint_data.unit) and _waypoint_data.unit:key() == unit_key then 
				local old_waypoint_data = self:RemoveWaypoint(user_id,i)
				--break --replace the marker
				return --or cancel entirely
			end
		end
		
		--check for valid interaction on unit
		local interaction_ext = unit.interaction and unit:interaction()
		if interaction_ext then 
			if interaction_ext:disabled() and interaction_ext:active() and interaction_ext:can_interact() then
				is_interactable = true
				interaction_tweak_id = interaction_ext.tweak_data
			end
		end
	
		if unit:in_slot(managers.slot._masks.pickups) then
			self:log("Pinged a pickup")
		elseif unit:in_slot(managers.slot._masks.enemies) then
			self:log("Pinged an enemy")
		end
	end
	
	if self._selected_ping then 
		local _waypoint_data,_index = self:GetWaypointById(self._selected_ping.user_id,self._selected_ping.waypoint_id)
		if _waypoint_data then 
			if self._selected_ping.user_id == user_id then 
				self:RemoveWaypoint(user_id,_index)
			else
				--respond to waypoint
				self:PlayCriminalSound("v01") -- "I'm on it!"
			end
			self._selected_ping = nil
			return
		end
	end
	
	--if generic ping, automatically determine the icon, text, etc.
	if contextual then 
		if is_interactable then 
			params = self.waypoint_parameters.interact
			if interaction_tweak_id then 
				
				local interaction_tweak_data = tweak_data.interaction[interaction_tweak_id]
				local contextual_interaction_data = self.tweak_data.contextual_interactions[interaction_tweak_id]
				if contextual_interaction_data then 
					sound_id = contextual_interaction_data.sound_id
					anim_id = contextual_interaction_data.anim_id
					
					params = self.tweak_data.waypoint_parameters[contextual_interaction_data.ping_type] or params
				end
			end
		else
			--other case-specific bases
		end
	end
	
	icon_id = icon_id or params.icon_id
	icon_type = icon_type or params.icon_type
	text_id = text_id or params.text_id
	custom_text = custom_text or params.custom_text
	color = color or params.color
	
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
	
	local my_peer_id = managers.network:session():local_peer():id()
	local peer_color = tweak_data.chat_colors[my_peer_id or 5]
	
	local creation_data = {
		waypoint_id = waypoint_id,
		user_id = user_id,
		icon_id = icon_id,
		icon_type = icon_type,
		text_id = text_id,
		custom_text = custom_text,
		peer_color = peer_color,
		color = color,
		position = hit_position,
		unit = unit,
		is_world = is_world,
		is_character = is_character,
		is_dead = is_dead,
		light_enabled = light_enabled,
		workspace_enabled = workspace_enabled,
		inherit = nil
	}
	
	local waypoint_data = self:AddWaypoint(creation_data)
	if waypoint_data then 
		waypoint_data.color = color
		waypoint_data.beam_color = peer_color
		waypoint_data.unit = unit
		waypoint_data.ping_type = ping_type
		waypoint_data.position = hit_position
		if params.duration then 
			params.end_t = params.duration + Application:time()
		end
		waypoint_data.waypoint_id = waypoint_id
		waypoint_data.is_dead = is_dead
		waypoint_data.is_character = is_character
		waypoint_data.is_world = is_world
		waypoint_data.creation_data = creation_data
		
		self.num_waypoints = waypoint_id --incremented waypoint counter
		self:log("You pinged " .. tostring(target_category) .. " - " .. tostring(target_name))
		
		
		if #self.active_waypoints[user_id] > self:GetMaxPingsPerPlayer() then 
			self:RemoveWaypoint(user_id,#self.active_waypoints[user_id])
		end
		
		self:RegisterWaypoint(user_id,waypoint_data)
	end
	
end

--create hud indicators with this waypoint data
--[[ table creation_data:
	waypoint_id: the unique identifier for this waypoint. presented as an int, which incremements +1 with each waypoint from its parent user. can be used to retrieve or destroy this specific waypoint
	icon_id: string. the identifier for the icon. used in conjunction with icon_type to determine the icon
	icon_type: int. determines where to retrieve the texture from, in conjunction with icon_id. [1] indicates hudiconstweakdata source; [2] indicates premade (texture and texture_rect determined by this mod's tweakdata instead).
	text_id: the identifier for the string that should be displayed alongside this waypoint, as according to this mod's tweakdata. localized.
	custom_text: the custom text that should be displayed alongside this waypoint. can be disabled for waypoints from other players. not localized.
	color: Color or string. If string, auto-converts to Color. Determines the icon color, beam color, and spotlight color.
	position: Vector3. The position for this waypoint.
	unit: Unit. The unit to attach the custom workspace to, if enabled.
	is_world: boolean. indicates whether this waypoint is a static positional waypoint. if true, does not use the raycasted unit as the waypoint position for updating the waypoint position.
	is_character: boolean. indicates whether this waypoint is a dynamically-positioned waypoint; if true, updates the waypoint position every frame according to the unit.
	light_enabled: boolean. 
	light_rotation: if true,
	workspace_enabled: boolean. if true, creates a world workspace along with the waypoint data.
	inherit: a list of keys, corresponding to keys of items in parameters. for each key present in inherit, it will be duplicated directly to the resulting output table
	
	--this is agnostic of the owner user and can be called either from local user waypoints or from other players syncing waypoints
--]]
function QuickChat:AddWaypoint(creation_data)
	local parent_panel = managers.hud._workspace:panel()
	if alive(parent_panel) then
		local waypoint_id = tostring(creation_data.waypoint_id)
		
		local light_enabled = creation_data.light_enabled
		local workspace_enabled = creation_data.workspace_enabled
		local is_world = creation_data.is_world
		local is_character = creation_data.is_character
		local position = creation_data.position
		local peer_color = creation_data.peer_color or Color.white
		local owner_id = creation_data.user_id
		
		local waypoint_data = {
			position = position
--,			panel_position = Vector3()
		}
		
		--get icon data
		local texture,texture_rect
		local icon_id = creation_data.icon_id
		local icon_type = creation_data.icon_type
		if icon_id then 
			if icon_type == 1 then 
				texture,texture_rect = tweak_data.hud_icons:get_icon_data(icon_id)
			elseif icon_type == 2 then 
				local icon_tweakdata = self.tweak_data.premade_icons[icon_id]
				if icon_tweakdata then 
					texture = icon_tweakdata.texture
					texture_rect = icon_tweakdata.texture_rect
					--todo icon-specific w/h ratio from tweakdata
				end
			end
		end
		if not texture then 
			self:log("ERROR: AddWaypoint() from owner " .. tostring(owner_id) .. ", waypoint_id " .. tostring(waypoint_id) .. " gave invalid icon: " .. tostring(icon_id) .. " (" .. type(icon_type) .. " " .. tostring(icon_type) .. ")")
			return
		end
		
		--get text data
		local text
		local text_id = creation_data.text_id
		local custom_text = creation_data.custom_text
		if custom_text and (owner_id == self.USER_ID or self:ShouldAllowSyncCustomText()) then 
			text = custom_text
		elseif text_id then 
			local _text_id = self.tweak_data.premade_text_messages[text_id]
			if _text_id then 
				text = managers.localization:text(_text_id)
			end
		end
		if not text then 
			self:log("ERROR: No valid text for text_id " .. tostring(text_id))
			return
		end
		
		
		--create gui objects
		local bitmap_size = self.tweak_data.gui_bitmap.size
		local panel = parent_panel:panel({
			name = waypoint_id,
			w = self.tweak_data.gui_panel.w,
			h = self.tweak_data.gui_panel.h
		})
		waypoint_data._panel = panel
		
		local bitmap = panel:bitmap({
			name = "bitmap",
			texture = texture,
			texture_rect = texture_rect,
			color = color,
			alpha = self.tweak_data.gui_bitmap.alpha,
			layer = self.tweak_data.gui_bitmap.layer
		})
		bitmap:set_y((panel:h() - bitmap:h()) / 2)
		waypoint_data._bitmap = bitmap
		
		local rect = panel:rect({
			w = bitmap_size,
			h = bitmap_size,
			rotation = self.tweak_data.gui_rect.rotation,
			alpha = self.tweak_data.gui_rect.alpha,
			layer = self.tweak_data.gui_rect.layer,
			color = peer_color
		})
		waypoint_data._rect = rect
		rect:set_center(bitmap:center())
		
		local arrow_icon_id = self.tweak_data.gui_arrow.icon_id
		local arrow_texture,arrow_texture_rect = tweak_data.hud_icons:get_icon_data(arrow_icon_id)
		local arrow = panel:bitmap({
			name = "arrow",
			texture = arrow_texture,
			texture_rect = arrow_texture_rect,
			w = self.tweak_data.gui_arrow.w,
			h = self.tweak_data.gui_arrow.h,
			color = Color.white,
			alpha = self.tweak_data.gui_arrow.alpha,
			layer = self.tweak_data.gui_arrow.layer
		})
		waypoint_data._arrow = arrow
		
		waypoint_data.x_offset = -bitmap_size / 2
		
		local text = panel:text({
			name = "text",
			text = tostring(text),
			align = "left",
			x = bitmap_size * 1.5,
			font = self.tweak_data.gui_text.font,
			font_size = self.tweak_data.gui_text.font_size,
			vertical = "center",
			alpha = self.tweak_data.gui_text.alpha,
			layer = self.tweak_data.gui_text.layer,
			color = self.tweak_data.gui_text.color
		})
		waypoint_data._text = text
		
		if workspace_enabled then 
			--todo floor workspace 
			
			local w = self.tweak_data.gui_workspace.w
			local h = self.tweak_data.gui_workspace.h
			local world_w = w * self.tweak_data.gui_workspace.world_scale
			local world_h = h * self.tweak_data.gui_workspace.world_scale
			
			local start_pos = position or start_pos
			
			local ws = self._gui:create_world_workspace(world_w,world_h,start_pos - Vector3(0,world_h/2,0),Vector3(world_w,0,0),Vector3(0,world_h,0))
			
			ws:set_billboard(Workspace.BILLBOARD_BOTH)
			
			ws:panel():rect({
				name = "debug",
				color = color,
				alpha = 0.25
			})
			
			--mysteriously nonfunctional
			ws:panel():bitmap({
				name = "bitmap",
				w = w,
				h = h,
				texture = tweak_data.hud_icons.wp_arrow.texture,
				texture_rect = tweak_data.hud_icons.wp_arrow.texture_rect,
				color = Color.white,
				alpha = self.tweak_data.gui_bitmap.alpha
			})
			
			if unit and not is_world then 
				local head_obj = unit:get_object(Idstring("Head"))
				if is_character and head_obj then 
					local attachment_obj = head_obj or unit:orientation_object()
					local oobb = attachment_obj:oobb()
					ws:set_linked(world_w,world_h,attachment_obj,oobb:center() - Vector3(0,world_h/2,0),Vector3(world_w,0,0),Vector3(0,world_h,0))
				else
					local attachment_obj = unit:orientation_object()
					ws:set_linked(world_w,world_h,attachment_obj,attachment_obj:position() - position,Vector3(world_w,0,0),Vector3(0,world_h,0))
				end
			end
			waypoint_data._workspace = ws
		end
		
		--create spotlight
		if light_enabled then 
			local light_texture = creation_data.light_texture or self.tweak_data.spotlight.texture 
			local spotlight = World:create_light("spot|specular|plane_projection", light_texture)
			waypoint_data._spotlight = spotlight
			spotlight:set_position(creation_data.position + self.tweak_data.spotlight.offset_position)
			spotlight:set_color(peer_color)
			spotlight:set_spot_angle_end(self.tweak_data.spotlight.angle or 60)
			spotlight:set_far_range(self.tweak_data.spotlight.range or 10000)
			spotlight:set_multiplier(self.tweak_data.spotlight.mul_index or 2)
			local spot_rot = creation_data.light_rotation or self.tweak_data.spotlight.rotation
			if spot_rot then
				spotlight:set_rotation(spot_rot)
			end
			spotlight:set_enable(true)
		end
		
		--pass on any creation parameters specified
		if creation_data.inherit and type(creation_data.inherit) == "table" then 
			for _,key in pairs(creation_data.inherit) do 
				waypoint_data[key] = creation_data[key]
			end
		end
		
		return waypoint_data
	else
		self:log("ERROR: AddWaypoint() failed- parent panel does not exist")
	end
end


function QuickChat:RemoveWaypoint(id64,index)
	local waypoint = self:UnregisterWaypoint(id64,index)
	if waypoint then 
		if id64 == self.USER_ID then 
			self:SyncRemoveWaypointToPeers(waypoint.waypoint_id)
		end
		self:DestroyWaypoint(waypoint)
	end
end

--register user waypoint (both from local user and from peers)
function QuickChat:RegisterWaypoint(id64,waypoint_data)
	if id64 then 
		self.active_waypoints[id64] = self.active_waypoints[id64] or {}
		table.insert(self.active_waypoints[id64],1,waypoint_data)
		
		if id64 == self.USER_ID then 
			self:SyncWaypointToPeers(waypoint_data)
		end
		return true
	else
		self:log("ERROR: QuickChat:RegisterWaypoint(" .. tostring(id64) .. "): Bad id64!")
	end
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
	
	if waypoint_data._spotlight then 
		if waypoint_data._spotlight ~= -1 then 
			World:delete_light(waypoint_data._spotlight)
		end
		waypoint_data._spotlight = nil
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

function QuickChat:GetWaypointByIndex(id64,index)
	return self.active_waypoints[id64] and self.active_waypoints[id64][index]
end

function QuickChat:GetWaypointById(id64,id)
	if id64 and self.active_waypoints[id64] then 
		for index,waypoint_data in pairs(self.active_waypoints[id64]) do 
			if waypoint_data.waypoint_id == id then 
				return waypoint_data,index
			end
		end
	end
end

function QuickChat:ClearAllWaypointsByPeer(id64)
	if self.active_waypoints[id64] then 
		for i=#self.active_waypoints[id64],1,-1 do 
			local waypoint_data = table.remove(self.active_waypoints[id64],i)
			if waypoint_data then 
				self:DestroyWaypoint(waypoint_data)
			end
		end
	end
end

function QuickChat:ClearAllWaypoints()
	for user_id,waypoints_list in pairs(self.active_waypoints) do 
		for i=#waypoints_list,1,-1 do 
			local waypoint_data = table.remove(waypoints_list,i)
			if waypoint_data then 
				if user_id == self.USER_ID then 
					self:SyncRemoveWaypointToPeers(waypoint_data.waypoint_id)
				end
				self:DestroyWaypoint(waypoint_data)
			end
		end
	end
end

	-- Network/syncing --

function QuickChat:RegisterPeer(peer,version_id)
	local id64 = peer:id()
	self.registered_peers[id64] = self.registered_peers[id64] or {}
	self.registered_peers[id64].version_id = version_id
end

function QuickChat:SyncWaypointToPeers(waypoint_data)
	local waypoint_string = self:GetWaypointString(waypoint_data.creation_data)
	local debug_enabled = self.settings.debug_log_enabled
	if waypoint_string then 
		local session = managers.network:session()
		local local_peer_id = session:local_peer():id()
		for _,peer in pairs(session:all_peers()) do 
			local peer_id = peer:id()
			if debug_enabled or peer_id ~= local_peer_id then 
				local id64 = peer:user_id()
				local peer_data = self.registered_peers[id64] 
				local network_message = self._network_data.current_sync_ids.add
				if peer_data and peer_data.version_id then 
					if self._network_data.sync_functions_by_version[peer_data.version_id] then 
						network_message = self._network_data.sync_functions_by_version[peer_data.version_id].add or network_message
					end
				end
				LuaNetworking:SendToPeer(peer_id,network_message,waypoint_string)
			end
		end
	end
end

function QuickChat:SyncRemoveWaypointToPeers(waypoint_id)
	local debug_enabled = self.settings.debug_log_enabled
	if waypoint_id then 
		local session = managers.network:session()
		local local_peer_id = session:local_peer():id()
		for _,peer in pairs(session:all_peers()) do 
			local peer_id = peer:id()
			if debug_enabled or peer_id ~= local_peer_id then 
				local id64 = peer:user_id()
				local peer_data = self.registered_peers[id64] 
				local network_message = self._network_data.current_sync_ids.remove
				if peer_data and peer_data.version_id then 
					if self._network_data.sync_functions_by_version[peer_data.version_id] then 
						network_message = self._network_data.sync_functions_by_version[peer_data.version_id].remove or network_message
					end
				end
				LuaNetworking:SendToPeer(peer_id,network_message,waypoint_id)
			end
		end
	end
end

--syncs waypoints belonging to the local peer to the new drop-in
--todo do these on a slight delay between each so as not to cause hitching when there are large numbers of waypoints
	--note: peer should be checked in this case to ensure that the peer is still connected and prevent errors
function QuickChat:SyncWaypointsToDropInPeer(peer)
	local peer_id = peer:id()
	for i,waypoint_data in pairs(self.active_waypoints[self.USER_ID]) do 
		local waypoint_string = self:GetWaypointString(waypoint_data.creation_data)
		
		local peer_data = self.registered_peers[id64] 
		local network_message = self._network_data.current_sync_ids.add
		if peer_data and peer_data.version_id then 
			if self._network_data.sync_functions_by_version[peer_data.version_id] then 
				network_message = self._network_data.sync_functions_by_version[peer_data.version_id].add or network_message
			end
		end
		LuaNetworking:SendToPeer(peer_id,network_message,waypoint_string)
		
		LuaNetworking:SendToPeer(peer_id,network_message,waypoint_string)

	end
end

--todo valid checking for all parameters
function QuickChat:GetWaypointString(data)
	local waypoint_id = data.waypoint_id
	local text_id = data.text_id
	local custom_text = " "
	if self:ShouldAllowSyncCustomText() then 
		custom_text = data.custom_text or " "
	end
	local icon_type = data.icon_type
	local icon_id = data.icon_id
	local end_t = data.duration and (data.duration + Application:time()) or data.end_t or "nil"
	local show_timer = tostring(data.show_timer and true or false)
	local position = data.position and math.vector_to_string(data.position)
	local uid
	local is_world = data.is_world
	if data.unit and not is_world then 
		uid = data.unit:id()
		--get syncable unit id number
	else
		uid = "nil"
	end
	local is_character = data.is_character
	local is_dead = data.is_dead
	if waypoint_id and text_id and icon_type and icon_id and position then
		return table.concat({
			tostring(waypoint_id),
			tostring(text_id),
			tostring(custom_text),
			tostring(icon_type),
			tostring(icon_id),
			end_t,
			show_timer,
			position,
			uid,
			tostring(is_character),
			tostring(is_world),
			tostring(is_dead)
		},"|")
	else
		self:log("QuickChat:GetWaypointString(" .. tostring(data) .. "): Unable to pack waypoint- missing parameters!")
		self:log(
		"data: < waypoint_id = " ..
		tostring(data.waypoint_id) ..
		", text_id = " .. 
		tostring(data.text_id) ..
		", icon_type = " .. 
		tostring(data.icon_type) ..
		", icon_id = " .. 
		tostring(data.icon_id) ..
		", position = " .. 
		tostring(data.position) ..
		" />")
	end
end

--used for incoming sync waypoints
function QuickChat.FindTargetUnit(id,mask)
	for _,unit in pairs(World:find_units_quick("all", mask)) do
		if unit:id() == id then
			return unit
		end
	end
end
--return QuickChat.FindTargetUnit(1250,QuickChat.cast_slotmasks.all)

--on network message received:
Hooks:Add("NetworkReceivedData", "NetworkReceivedData_QuickChat", function(sender, message_id, message)
	local peer = managers.network:session():peer(sender)
	if not peer or managers.chat and managers.chat:is_peer_muted(peer) then
		--don't do anything because peer is muted
		--blocked. unfollowed. reported.
	else
		local func_name = message_id and QuickChat._network_data.sync_functions_by_name[message_id] --whitelist so that peers can't remotely execute functions willy-nilly
		if message_id and func_name then 
			if func_name and type(QuickChat[func_name]) == "function" then 
				local success,e = QuickChat[func_name](QuickChat,peer,message)
				if not success then 
					QuickChat:log("NetworkReceivedData_QuickChat: Failed to receive sync data. No valid ping_data found! Sender " .. tostring(sender) .. ", message_id " .. tostring(message_id) .. " message < " .. tostring(message) .. " >")
					if e then 
						QuickChat:log(tostring(e))
					end
				end
			end
		end
	end
end)

function QuickChat:Register_v1(peer,message)
	local version_id = message
	self:RegisterPeer(peer,version_id)
end

function QuickChat:SyncAddWaypoint_v1(peer,message)
	local data = string.split(message,"|")
	if data then 
		local string_to_bool = QuickChat.string_to_bool
		local utf8_len = utf8.len
	
		local waypoint_id_str = data[1]
		local waypoint_id = waypoint_id_str and tonumber(waypoint_id_str)
		if not waypoint_id then 
			return false,"Invalid waypoint_id: " .. tostring(waypoint_id_str)
		end
		
		local text_id = data[2]
		if not text_id or utf8_len(text_id) == 0 then
			return false,"Invalid text_id: " .. tostring(text_id)
		end
		
		local custom_text
		local custom_text_str = data[3]
		if utf8_len(custom_text_str) <= 1 then 
			custom_text = nil
		end
		
		local icon_type_str = data[4]
		local icon_type = icon_type_str and tonumber(icon_type_str)
		if not icon_type then 
			return false,"Invalid icon_type: " .. tostring(icon_type)
		end
		
		local icon_id = data[5]
		if not text_id or utf8_len(text_id) <= 1 then 
			return false,"Invalid icon_id: " .. tostring(icon_id)
		end
		
		local end_t_str = data[6]
		local end_t = end_t_str and tonumber(end_t_str)
		
		local show_timer_str = data[7]
		local show_timer = string_to_bool(show_timer_str)
		
		local position_str = data[8]
		local position = position_str and math.string_to_vector(position_str)
		if not position then 
			return false,"Invalid position: " .. tostring(position_str)
		end
		
		local uid_str = data[9]
		local uid = uid_str and tonumber(uid_str)
		local mask = self.cast_slotmasks.all
			--todo sync a slotmask identifier to reduce search overhead
		local unit = uid and QuickChat.FindTargetUnit(uid,mask)
		if unit and alive(unit) then 
			self:log("Successfully found synced unit " .. tostring(unit:key()) .. " from uid " .. tostring(uid))
		else
			self:log("No unit found from synced uid " .. tostring(uid))
		end
		
		local is_character_str = data[10]
		local is_character = string_to_bool(is_character_str)
		
		local is_world_str = data[11]
		local is_world = string_to_bool(is_world_str)
		
		local is_dead_str = data[12]
		local is_dead = string_to_bool(is_dead_str)
		
		local peer_id = peer:id()
		local peer_color = tweak_data.chat_colors[peer_id or 5] or Color(0,1,1)
		
		local params = {
			waypoint_id = waypoint_id,
			text_id = text_id,
			custom_text = custom_text,
			peer_color = peer_color,
			icon_type = icon_type,
			icon_id = icon_id,
			end_t = end_t,
			show_timer = show_timer,
			position = position,
			unit = unit,
			is_character = is_character,
			is_world = is_world,
			is_dead = is_dead,
			
			light_enabled = true,
			workspace_enabled = false,
			inherit = {
				"waypoint_id",
				"unit",
				"show_timer",
				"is_character",
				"is_world",
				"is_dead"
			}
		}
		local waypoint_data = self:AddWaypoint(params)
		if waypoint_data then 
			local id64 = peer:user_id()
			local success = self:RegisterWaypoint(id64,waypoint_data)
			local e 
			if not success then 
				e = "Could not register user " .. tostring(id64)
			end
			return success,e
		else
			return false,"AddWaypoint() failed"
		end
	end
end

function QuickChat:SyncRemoveWaypoint_v1(peer,message)
	local waypoint_id = tonumber(message)
	local user_id = peer:user_id()
	local waypoint,index = self:GetWaypointById(user_id,waypoint_id)
	if waypoint then 
		self:UnregisterWaypoint(user_id,index)
		self:DestroyWaypoint(waypoint)
		return true
	else
		return false,"No waypoint by id (" .. type(waypoint_id) .. " " .. tostring(waypoint_id) .. ") found"
	end
end
--return QuickChat.active_waypoints["76561198058237584"][1].waypoint_id


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
	
	MenuCallbackHandler.callback_pingwaypoint_debug = function(self,item)
		QuickChat.settings.debug_log_enabled = item:value() == "on"
		QuickChat:Save()
	end
	
	
	MenuCallbackHandler.callback_pingwaypoint_max_pings_per_player = function(self,item)
		QuickChat.settings.max_pings_per_player = tonumber(item:value())
		QuickChat:Save()
	end
	
	MenuCallbackHandler.func_pingwaypoint_keybind_ping = function(self)
		QuickChat:log("This should not be called")
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
	
	MenuHelper:LoadFromJsonFile(QuickChat._menu_path .. "options.json", QuickChat, QuickChat.settings)		
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


local assets = {
	{
		ext = Idstring("texture"),
		path = Idstring("guis/textures/pd2/quickchat/radial_bg"),
		file = QuickChat._assets_path .. "guis/textures/pd2/quickchat/radial_bg.texture"
	}


,	{
		ext = Idstring("texture"),
		path = Idstring("guis/textures/pd2/quickchat/radial_selector"),
		file = QuickChat._assets_path .. "guis/textures/pd2/quickchat/radial_selector.texture"
	}
--]]
}
for _, v in pairs(assets) do
	if not DB:has(v.ext, v.path) then
		BLT.AssetManager:CreateEntry(v.path, v.ext, v.file)
	end
end
