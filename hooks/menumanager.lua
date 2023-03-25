--TODO
	--SCHEMA
		--todo use _supported_controller_type_map instead of manual mapping?
			--may not be necessary if only the wrapper type is used
		--needs VR support

	--FEATURES
		--fadeout angle
		--allow mouse button binding for keyboard users
		--display current gamepad mode in menu
		--customization
			--custom radial messages (use QKI?)
			--preview radial in menu
			--button combos?
		--localize menu button names for controllers, per gamepad type
		--allow selecting button by waiting at menu (for controllers) for x seconds
			--(this allows controllers to bind or reserve any options they desire, without interfering with menu operation)

		
			--button/keybind to remove all waypoints
				--remove all waypoints data AND all panel children
	
	--BUGS
		--squish squash, no bugs here, only crimson flowers

QuickChat = QuickChat or {
	_radial_menu_manager = nil, --for reference
	_lip = nil 					--for reference
}
QuickChat._core = QuickChatCore
QuickChat._mod_path = (QuickChatCore and QuickChatCore.GetPath and QuickChatCore:GetPath()) or ModPath
QuickChat._save_path = SavePath .. "QuickChat/"
QuickChat._save_layouts_path = QuickChat._save_path .. "layouts/"
QuickChat._bindings_name = "bindings_$WRAPPER.json"
QuickChat._settings_name = "settings.json"
QuickChat.default_settings = {
	waypoints_max_count = 1
}
QuickChat.settings = table.deep_map_copy(QuickChat.default_settings) --general user pref
QuickChat.sort_settings = {
	"waypoints_max_count"
}
QuickChat._bindings = {
--[[
	callouts_1 = "j",
	deployables_1 = "k",
	custom_1 = "l"
--]]
}
QuickChat.SYNC_MESSAGE_PRESET = "QuickChat_message_preset"
QuickChat.SYNC_MESSAGE_REGISTER = "QuickChat_Register"
QuickChat.SYNC_MESSAGE_WAYPOINT_ADD = "QuickChat_SendWaypoint"
QuickChat.API_VERSION = "2" -- string!
QuickChat.WAYPOINT_RAYCAST_DISTANCE = 250000 --250m
QuickChat.WAYPOINT_SECONDARY_CAST_RADIUS = 50 --50cm

QuickChat.WAYPOINT_TYPES = {
	POSITION = 1,
	UNIT = 2
}
QuickChat._synced_waypoints = {
	{},{},{},{}
}

QuickChat._icon_presets = {
	{
		source = 1,
		icon_id = "pd2_lootdrop" --1
	},
	{
		source = 1,
		icon_id = "pd2_escape" --2
	},
	{
		source = 1,
		icon_id = "pd2_talk" --3
	},
	{
		source = 1,
		icon_id = "pd2_kill" --4
	},
	{
		source = 1,
		icon_id = "pd2_drill" --5
	},
	{
		source = 1,
		icon_id = "pd2_generic_look" --6
	},
	{
		source = 1,
		icon_id = "pd2_phone" --7
	},
	{
		source = 1,
		icon_id = "pd2_c4" --8
	},
	{
		source = 1,
		icon_id = "pd2_generic_saw" --9
	},
	{
		source = 1,
		icon_id = "pd2_chainsaw" --10
	},
	{
		source = 1,
		icon_id = "pd2_power" --11
	},
	{
		source = 1,
		icon_id = "pd2_door" --12
	},
	{
		source = 1,
		icon_id = "pd2_computer" --13
	},
	{
		source = 1,
		icon_id = "pd2_wirecutter" --14
	},
	{
		source = 1,
		icon_id = "pd2_fire" --15
	},
	{
		source = 1,
		icon_id = "pd2_loot" --16
	},
	{
		source = 1,
		icon_id = "pd2_methlab" --17
	},
	{
		source = 1,
		icon_id = "pd2_generic_interact" --18
	},
	{
		source = 1,
		icon_id = "pd2_goto" --19
	},
	{
		source = 1,
		icon_id = "pd2_ladder" --20
	},
	{
		source = 1,
		icon_id = "pd2_fix" --21
	},
	{
		source = 1,
		icon_id = "pd2_question" --22
	},
	{
		source = 1,
		icon_id = "pd2_defend" --23
	},
	{
		source = 1,
		icon_id = "wp_arrow" --24
	},
	{
		source = 1,
		icon_id = "pd2_car" --25
	},
	{
		source = 1,
		icon_id = "pd2_melee" --26
	},
	{
		source = 1,
		icon_id = "pd2_water_tap" --27
	},
	{
		source = 1,
		icon_id = "pd2_bodybag" --28
	},
	{
		source = 1,
		icon_id = "wp_vial" --29
	},
	{
		source = 1,
		icon_id = "wp_standard" --30
	},
	{
		source = 1,
		icon_id = "wp_revive" --31
	},
	{
		source = 1,
		icon_id = "wp_rescue" --32
	},
	{
		source = 1,
		icon_id = "wp_trade" --33
	},
	{
		source = 1,
		icon_id = "wp_powersupply" --34
	},
	{
		source = 1,
		icon_id = "wp_watersupply" --35
	},
	{
		source = 1,
		icon_id = "wp_drill" --36
	},
	{
		source = 1,
		icon_id = "wp_hack" --37
	},
	{
		source = 1,
		icon_id = "wp_talk" --38
	},
	{
		source = 1,
		icon_id = "wp_c4" --39
	},
	{
		source = 1,
		icon_id = "wp_crowbar" --40
	},
	{
		source = 1,
		icon_id = "wp_planks" --41
	},
	{
		source = 1,
		icon_id = "wp_door" --42
	},
	{
		source = 1,
		icon_id = "wp_saw" --43
	},
	{
		source = 1,
		icon_id = "wp_bag" --44
	},
	{
		source = 1,
		icon_id = "wp_exit" --45
	},
	{
		source = 1,
		icon_id = "wp_can" --46
	},
	{
		source = 1,
		icon_id = "wp_target" --47
	},
	{
		source = 1,
		icon_id = "wp_key" --48
	},
	{
		source = 1,
		icon_id = "wp_winch" --49
	},
	{
		source = 1,
		icon_id = "wp_escort" --50
	},
	{
		source = 1,
		icon_id = "wp_powerbutton" --51
	},
	{
		source = 1,
		icon_id = "wp_server" --52
	},
	{
		source = 1,
		icon_id = "wp_powercord" --53
	},
	{
		source = 1,
		icon_id = "wp_phone" --54
	},
	{
		source = 1,
		icon_id = "wp_scrubs" --55
	},
	{
		source = 1,
		icon_id = "wp_sentry" --56
	},
	{
		source = 1,
		icon_id = "equipment_trip_mine" --57
	},
	{
		source = 1,
		icon_id = "equipment_ammo_bag" --58
	},
	{
		source = 1,
		icon_id = "equipment_doctor_bag" --59
	},
	{
		source = 1,
		icon_id = "equipment_ecm_jammer" --60
	},
	{
		source = 1,
		icon_id = "equipment_money_bag" --61
	},
	{
		source = 1,
		icon_id = "equipment_bank_manager_key" --62
	},
	{
		source = 1,
		icon_id = "equipment_chavez_key" --63
	},
	{
		source = 1,
		icon_id = "equipment_drill" --64
	},
	{
		source = 1,
		icon_id = "equipment_ejection_seat" --65
	},
	{
		source = 1,
		icon_id = "equipment_saw" --66
	},
	{
		source = 1,
		icon_id = "equipment_cutter" --67
	},
	{
		source = 1,
		icon_id = "equipment_hack_ipad" --68
	},
	{
		source = 1,
		icon_id = "equipment_gold" --69
	},
	{
		source = 1,
		icon_id = "equipment_thermite" --70
	},
	{
		source = 1,
		icon_id = "equipment_c4" --71
	},
	{
		source = 1,
		icon_id = "equipment_cable_ties" --72
	},
	{
		source = 1,
		icon_id = "equipment_bleed_out" --73
	},
	{
		source = 1,
		icon_id = "equipment_planks" --74
	},
	{
		source = 1,
		icon_id = "equipment_sentry" --75
	},
	{
		source = 1,
		icon_id = "equipment_stash_server" --76
	},
	{
		source = 1,
		icon_id = "equipment_vialOK" --77
	},
	{
		source = 1,
		icon_id = "equipment_vial" --78
	},
	{
		source = 1,
		icon_id = "equipment_ticket" --79
	},
	{
		source = 1,
		icon_id = "equipment_files" --80
	},
	{
		source = 1,
		icon_id = "equipment_harddrive" --81
	},
	{
		source = 1,
		icon_id = "equipment_evidence" --82
	},
	{
		source = 1,
		icon_id = "equipment_chainsaw" --83
	},
	{
		source = 1,
		icon_id = "equipment_manifest" --84
	},
	{
		source = 1,
		icon_id = "equipment_fire_extinguisher" --85
	},
	{
		source = 1,
		icon_id = "equipment_winch_hook" --86
	},
	{
		source = 1,
		icon_id = "equipment_bottle" --87
	},
	{
		source = 1,
		icon_id = "equipment_sleeping_gas" --88
	},
	{
		source = 1,
		icon_id = "equipment_usb_with_data" --89
	},
	{
		source = 1,
		icon_id = "equipment_usb_no_data" --90
	},
	{
		source = 1,
		icon_id = "equipment_empty_cooling_bottle" --91
	},
	{
		source = 1,
		icon_id = "equipment_cooling_bottle" --92
	},
	{
		source = 1,
		icon_id = "equipment_bfd_tool" --93
	},
	{
		source = 1,
		icon_id = "equipment_elevator_key" --94
	},
	{
		source = 1,
		icon_id = "equipment_blow_torch" --95
	},
	{
		source = 1,
		icon_id = "equipment_printer_ink" --96
	},
	{
		source = 1,
		icon_id = "equipment_plates" --97
	},
	{
		source = 1,
		icon_id = "equipment_paper_roll" --98
	},
	{
		source = 1,
		icon_id = "equipment_key_chain" --99
	},
	{
		source = 1,
		icon_id = "equipment_hand" --100
	},
	{
		source = 1,
		icon_id = "equipment_briefcase" --101
	},
	{
		source = 1,
		icon_id = "equipment_soda" --102
	},
	{
		source = 1,
		icon_id = "equipment_chrome_mask" --103
	},
	{
		source = 1,
		icon_id = "equipment_born_tool" --104
	},
	{
		source = 1,
		icon_id = "equipment_liquid_nitrogen_canister" --105
	},
	{
		source = 1,
		icon_id = "equipment_medallion" --106
	},
	{
		source = 1,
		icon_id = "equipment_bloodvial" --107
	},
	{
		source = 1,
		icon_id = "equipment_bloodvialok" --108
	},
	{
		source = 1,
		icon_id = "equipment_chimichanga" --109
	},
	{
		source = 1,
		icon_id = "equipment_stapler" --110
	},
	{
		source = 1,
		icon_id = "equipment_compounda" --111
	},
	{
		source = 1,
		icon_id = "equipment_compoundb" --112
	},
	{
		source = 1,
		icon_id = "equipment_compoundc" --113
	},
	{
		source = 1,
		icon_id = "equipment_compoundd" --114
	},
	{
		source = 1,
		icon_id = "equipment_compoundok" --115
	},
	{
		source = 1,
		icon_id = "equipment_mayan_gold" --116
	},
	{
		source = 1,
		icon_id = "equipment_blueprint" --117
	},
	{
		source = 1,
		icon_id = "equipment_tape_fingerprint" --118
	},
	{
		source = 1,
		icon_id = "equipment_tape" --119
	},
	{
		source = 1,
		icon_id = "equipment_boltcutter" --120
	},
	{
		source = 1,
		icon_id = "equipment_policebadge" --121
	},
	{
		source = 1,
		icon_id = "equipment_flammable" --122
	},
	{
		source = 1,
		icon_id = "equipment_rfid_tag_01" --123
	},
	{
		source = 1,
		icon_id = "equipment_rfid_tag_02" --124
	},
	{
		source = 1,
		icon_id = "equipment_globe" --125
	},
	{
		source = 1,
		icon_id = "equipment_scythe" --126
	},
	{
		source = 1,
		icon_id = "equipment_electrical" --127
	},
	{
		source = 1,
		icon_id = "equipment_fertilizer" --128
	},
	{
		source = 1,
		icon_id = "equipment_timer" --129
	},
	{
		source = 1,
		icon_id = "equipment_documents" --130
	},
	{
		source = 1,
		icon_id = "equipment_syringe" --131
	},
	{
		source = 1,
		icon_id = "equipment_notepad" --132
	},
	{
		source = 1,
		icon_id = "equipment_cleaning_product" --133
	},
	{
		source = 1,
		icon_id = "equipment_defibrillator" --134
	},
	{
		source = 1,
		icon_id = "equipment_gas_canister" --135
	},
	{
		source = 1,
		icon_id = "equipment_businesscard" --136
	},
	{
		source = 1,
		icon_id = "equipment_car_jack" --137
	},
	{
		source = 1,
		icon_id = "equipment_cargo_strap" --138
	},
	{
		source = 1,
		icon_id = "equipment_audio_device" --139
	},
	{
		source = 1,
		icon_id = "equipment_laptop" --140
	},
	{
		source = 1,
		icon_id = "equipment_stock" --141
	},
	{
		source = 1,
		icon_id = "equipment_barrel" --142
	},
	{
		source = 1,
		icon_id = "equipment_receiver" --143
	},
	{
		source = 1,
		icon_id = "equipment_acid" --144
	},
	{
		source = 1,
		icon_id = "equipment_sheriff_star" --145
	},
	{
		source = 1,
		icon_id = "equipment_hammer" --146
	},
	{
		source = 1,
		icon_id = "equipment_silver_ingot" --147
	},
	{
		source = 1,
		icon_id = "equipment_mould" --148
	},
	{
		source = 1,
		icon_id = "equipment_muriatic_acid" --149
	},
	{
		source = 1,
		icon_id = "equipment_caustic_soda" --150
	},
	{
		source = 1,
		icon_id = "equipment_hydrogen_chloride" --151
	},
	{
		source = 2, --circle outline (ps button style)
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --152
		texture_rect = {
			0,0,
			32,32
		}
	},
	{
		source = 2, --square outline (ps button style)
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --153
		texture_rect = {
			1 * 32,0 * 32,
			32,32
		}
	},
	{
		source = 2, --x (ps button style)
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --154
		texture_rect = {
			2 * 32,0 * 32,
			32,32
		}
	},
	{
		source = 2, --triangle (ps button style)
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --155
		texture_rect = {
			3 * 32,0 * 32,
			32,32
		}
	},
	{
		source = 2, --number "1"
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --156
		texture_rect = {
			0 * 32,1 * 32,
			32,32
		}
	},
	{
		source = 2, --number "2"
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --157
		texture_rect = {
			0 * 32,1 * 32,
			32,32
		}
	},
	{
		source = 2, --number "3"
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --158
		texture_rect = {
			0 * 32,1 * 32,
			32,32
		}
	},
	{
		source = 2, --number "4"
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --159
		texture_rect = {
			0 * 32,1 * 32,
			32,32
		}
	},
	{
		source = 2, --capital letter "A"
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --160
		texture_rect = {
			0 * 32,2 * 32,
			32,32
		}
	},
	{
		source = 2, --capital letter "B"
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --161
		texture_rect = {
			1 * 32,2 * 32,
			32,32
		}
	},
	{
		source = 2, --capital letter "C"
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --162
		texture_rect = {
			2 * 32,2 * 32,
			32,32
		}
	},
	{
		source = 2, --capital letter "D"
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --163
		texture_rect = {
			3 * 32,2 * 32,
			32,32
		}
	},
	{
		source = 2, --capital letter "E"
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --164
		texture_rect = {
			0 * 32,3 * 32,
			32,32
		}
	},
	{
		source = 2, --capital letter "F"
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --165
		texture_rect = {
			1 * 32,3 * 32,
			32,32
		}
	},
	{
		source = 2, --"do not" symbol (circle bisected with diagonal cross)
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --166
		texture_rect = {
			2 * 32,3 * 32,
			32,32
		}
	},
	{
		source = 2, --checkmark symbol
		texture = "guis/textures/pd2/quickchatmod/waypoint_icons_atlas", --167
		texture_rect = {
			3 * 32,3 * 32,
			32,32
		}
	}
}

QuickChat._label_presets = {
	"qc_wp_look",							--1
	"qc_wp_go",								--2
	"qc_wp_loot",							--3
	"qc_wp_kill",							--4
	"qc_wp_deploy"							--5
}

QuickChat._message_presets = {
	"qc_ptm_general_yes",					--1
	"qc_ptm_general_no",					--2
	"qc_ptm_general_cheer",					--3
	"qc_ptm_general_greeting",				--4
	"qc_ptm_general_thanks",				--5
	"qc_ptm_general_apology",				--6
	"qc_ptm_general_curse",					--7
	"qc_ptm_general_forgive",				--8
	"qc_ptm_general_acknowledged",			--9
	"qc_ptm_general_goodgame_normal",		--10
	"qc_ptm_general_goodgame_toxic",		--11
	"qc_ptm_general_bye",					--12
	"qc_ptm_general_brb",					--13
	"qc_ptm_general_nokeyboard",			--14
	"qc_ptm_general_leaving_now",			--15
	"qc_ptm_general_leaving_soon",			--16
	"qc_ptm_general_leaving_last_game",		--17
	"qc_ptm_general_healembargo",			--18
	"qc_ptm_general_achievementhunting",	--19
	"qc_ptm_comms_help",					--20
	"qc_ptm_comms_follow",					--21
	"qc_ptm_comms_attack",					--22
	"qc_ptm_comms_defend",					--23
	"qc_ptm_comms_regroup",					--24
	"qc_ptm_comms_reviving",				--25
	"qc_ptm_comms_summon",					--26
	"qc_ptm_comms_caution",					--27
	"qc_ptm_comms_opening_door",			--28
	"qc_ptm_comms_jammed_drill",			--29
	"qc_ptm_comms_jammed_hack",				--30
	"qc_ptm_direction_left",				--31
	"qc_ptm_direction_right",				--32
	"qc_ptm_direction_up",					--33
	"qc_ptm_direction_down",				--34
	"qc_ptm_direction_forward",				--35
	"qc_ptm_direction_backward",			--36
	"qc_ptm_tactic_ask_stealth",			--37
	"qc_ptm_tactic_ask_hybrid",				--38
	"qc_ptm_tactic_ask_loud",				--39
	"qc_ptm_tactic_suggest_stealth",		--40
	"qc_ptm_tactic_suggest_hybrid",			--41
	"qc_ptm_tactic_suggest_loud",			--42
	"qc_ptm_need_docbag",					--43
	"qc_ptm_need_fak",						--44
	"qc_ptm_need_ammo",						--45
	"qc_ptm_need_ecm",						--46
	"qc_ptm_need_sentrygun",				--47
	"qc_ptm_need_sentrygun_silent",			--48
	"qc_ptm_need_tripmine",					--49
	"qc_ptm_need_shapedcharge",				--50
	"qc_ptm_need_grenades",					--51
	"qc_ptm_need_convert",					--52
	"qc_ptm_need_ties",						--53
	"qc_ptm_enemy_sniper",					--54
	"qc_ptm_enemy_cloaker",					--55
	"qc_ptm_enemy_taser",					--56
	"qc_ptm_enemy_dozer",					--57
	"qc_ptm_enemy_medic",					--58
	"qc_ptm_enemy_shield",					--59
	"qc_ptm_enemy_winters"					--60
}

QuickChat._radial_menus = {} --generated radial menus
QuickChat._radial_menu_params = {} --ungenerated radial menus; populated with user data

QuickChat._callback_bind_button = nil --dynamically set
QuickChat._updaters = {}
	
QuickChat._input_cache = {}

QuickChat.allowed_binding_buttons = { --wrapper-specific bindings
	pc = {
		--potential buttons map is stored differently for keyboard, but should be unpacked into broadly the same format
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

local mvec3_distance = mvector3.distance

function QuickChat:Log(msg)
	if Console then
		Console:Log(msg)
	end
end

function QuickChat:GetMaxNumWaypoints()
	return self.settings.waypoints_max_count
end

function QuickChat:GetIconDataByIndex(icon_index)
	if icon_index then
		local icon_data = self._icon_presets[icon_index]
		if icon_data then
			if icon_data.source == 1 then
				return tweak_data.hud_icons:get_icon_data(icon_data.icon_id)
			elseif icon_data.source == 2 then
				return icon_data.texture,icon_data.texture_rect
			end
		end
	end
end

--Setup

function QuickChat:Setup() --on game setup complete
	self:PopulateInputCache()
	if managers.hud then
		local ws = managers.hud._saferect
		self._ws = ws
		local ws_panel = ws:panel()
		self._parent_panel = ws_panel:panel({
			name = "quickchat_parent_panel",
			valign = "grow",
			halign = "grow",
			layer = 4
		})
	end
	self:AddUpdater("QuickChat_UpdateInGame",callback(self,self,"UpdateGame"),false)
end

function QuickChat:LoadCustomRadials()
	local file_util = _G.file
	if self._lip then
		local directory_exists = file_util.DirectoryExists
		local file_exists = file_util.FileExists
		local function get_files(path)
			if SystemFS and SystemFS.list then 
				return SystemFS:list(path)
			else
				return file_util.GetFiles(path)
			end
			--this should be alphabetized
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
		local default_layouts_path = self._mod_path .. "layouts/"
		local files = get_files(default_layouts_path)
		for _,filename in pairs(files) do 
			local ext = string.sub(filename,-4)
			if ext == ".ini" then
				--check if get_files is alphabetized
				local ini_data = self._lip.load(default_layouts_path .. filename)
				local radial_id,new_radial_data = self:LoadMenuFromIni(ini_data)
				if new_radial_data then
					radial_id = radial_id or string.sub(filename,1,-5)
					self._radial_menu_params[radial_id] = new_radial_data
				end
			end
		end
		
		--load custom layouts last so that they can overwrite existing defaults
		local custom_layouts_path = self._save_layouts_path
		if not directory_exists(custom_layouts_path) then 
			make_dir(custom_layouts_path)
		end
		
		local files = get_files(custom_layouts_path)
		for _,filename in pairs(files) do 
			local ext = string.sub(filename,-4)
			if ext == ".ini" then
				local ini_data = self._lip.load(custom_layouts_path .. filename)
				local radial_id,new_radial_data = self:LoadMenuFromIni(ini_data)
				if new_radial_data then
					radial_id = radial_id or string.sub(filename,1,-5)
					self._radial_menu_params[radial_id] = new_radial_data
				end
			end
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
		
		if wrapper_type == "pc" then 
			for button_index,controllerbutton in ipairs(allowed_wrapper_buttons) do
				QuickChat._allowed_binding_buttons[Idstring(controllerbutton):key()] = controllerbutton
			end
			--todo load mouse buttons here
		else
			for controllerbutton,wrapperbutton in pairs(allowed_wrapper_buttons) do
				QuickChat._allowed_binding_buttons[Idstring(controllerbutton):key()] = controllerbutton
			end
		end
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
			"reset_mouse_position_on_show",
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
			
			if body.ping_as_default then 
--				new_menu_params.callback_on_cancelled = callback(self,self,"AddWaypoint")
				new_menu_params.callback_on_cancelled = function() local success,err = blt.pcall(callback(self,self,"AddWaypoint")) if err then self:Log(err) end end
			end
			
			new_menu_params.texture_highlight = body.texture_highlight or default_menu_data.texture_highlight
			new_menu_params.texture_darklight = body.texture_darklight or default_menu_data.texture_darklight
			new_menu_params.texture_cursor = body.texture_cursor or default_menu_data.texture_cursor
			
			for i,item_data in ipairs(ini_data) do 
				local new_item = {}
				if item_data.icon_index and self._icon_presets[item_data.icon_index] then
					local texture,texture_rect = self:GetIconDataByIndex(item_data.icon_index)
					new_item.texture = texture
					new_item.texture_rect = texture_rect
				elseif item_data.texture then
					new_item.texture = item_data.texture
					if item_data.texture_rect then 
						new_item.texture_rect = string.split(item_data.texture_rect,",")
					end
				end
				
				local message_preset_index = item_data.preset_text_index and self._message_presets[item_data.preset_text_index]
				local message_preset_name = message_preset_index and self._message_presets[message_preset_index]
				if message_preset_name then 
					new_item.preset_text_index = message_preset_index
					new_item.text = managers.localization:text(message_preset_name)
				elseif item_data.text then 
					new_item.text = item_data.text
				end
				if item_data.preview_text then --not localized
					new_item.text = item_data.preview_text
				elseif message_preset_name then
					new_item.text = managers.localization:text(message_preset_name)
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
				else
					new_item.callback = callback(self,self,"CallbackRadialSelection",item_data)
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

function QuickChat:CallbackRadialSelection(item_data)
	local preset_text_index = item_data.preset_text_index
	local text = item_data.text
	if preset_text_index then 
		self:SendPresetMessage(preset_text_index)
	elseif text then
		self:SendChatToAll(text)
	end
	if item_data.waypoint then
		self:AddWaypoint(item_data)
	end
end

--Waypoints
function QuickChat:AddWaypoint(params)
	params = params or {}
	
	local viewport_cam = managers.viewport:get_current_camera()
	if not viewport_cam then 
		--doesn't typically happen, usually for only a brief moment when all four players go into custody
		return 
	end
	local cam_pos = viewport_cam:position()
	local cam_aim = viewport_cam:rotation():y()
	
	local to_pos = cam_pos + (cam_aim * self.WAYPOINT_RAYCAST_DISTANCE)
	
	local mode = 1
	
	local raycast
	if mode == 1 then --precise raycast
		raycast = World:raycast("ray",cam_pos,to_pos,"slot_mask",managers.slot:get_mask("bullet_impact_targets")) or {}
	else
		--cylinder cast
		raycast = nil
	end
	if raycast then
		local unit_result
		local unit = raycast.unit
		local position = raycast.position
		local end_t
		if params.timer and params.timer > 0 then
			end_t = TimerManager:game():time() + params.timer
		end
		local label_index = params.label_index or 0
		local icon_index = params.icon_index or 0
		
		if unit then
			local function find_interactable(this_unit)
				if this_unit.interaction then 
					if this_unit:interaction() and not this_unit:interaction()._disabled and this_unit:interaction()._active then
						--look for any interactable object
						--not just any objects with an interaction extension- 
						--must be active and currently interactable
					
		--				self:log("active=" .. tostring(this_unit:interaction()._active) .. ",disabled=".. tostring(this_unit:interaction()._disabled))
						return this_unit
					end
				end
			end
			
			local function find_character(this_unit,no_further)
				if alive(this_unit) then
					if not no_further and this_unit:in_slot(8) and this_unit.parent and this_unit:parent() then 
						return find_character(this_unit:parent(),true)
					elseif this_unit.character_damage and this_unit:character_damage() and not this_unit:character_damage():dead() then
						return this_unit
			--		elseif this_unit:parent() and alive(this_unit:parent():base()) and this_unit:parent():base().tweak_table then 
					end
				end
			end
			
			if unit and alive(unit) then 
				unit_result = find_character(unit) or find_interactable(unit)
			end
			
			if not unit_result then
				--do secondary sphere cast to catch interactables specifically
				local spherecast = World:find_units_quick("sphere",position,self.WAYPOINT_SECONDARY_CAST_RADIUS,1)
				for _,_unit in ipairs(spherecast) do 
					local found_interactable = find_interactable(_unit)
					if found_interactable then
						unit_result = found_interactable
						break
					end
				end
				
			end
			
			local waypoint_type
			local _unit_id,unit_id
			if alive(unit_result) then
				--check if valid unit
				_unit_id = unit:id()
			end
			if _unit_id and _unit_id > 0 then	
				--attach waypoint to unit
				waypoint_type = self.WAYPOINT_TYPES.UNIT
				unit_id = _unit_id
			else
				--create waypoint at position
				waypoint_type = self.WAYPOINT_TYPES.POSITION
			end
			
--			local peer_id = managers.network:session():local_peer():id()
--			local peer_color = tweak_data.chat_colors[peer_id]
			local waypoint_data = {
				waypoint_type = waypoint_type,
				icon_index = icon_index,
				label_index = label_index,
				end_t = end_t,
				position = position,
				unit_id = unit_id,
				unit = unit_result
			}
			local peer_id = managers.network:session():local_peer():id()
			
			self:_SendWaypoint(waypoint_data)
			self:_AddWaypoint(peer_id,waypoint_data)
		end
	end
	
end

function QuickChat:_SendWaypoint(waypoint_data)
	local sync_string
	local waypoint_type = waypoint_data.waypoint_type
	local timer_string = waypoint_data.timer_string
	local label_index = waypoint_data.label_index
	local icon_index = waypoint_data.icon_index
	local unit_id = waypoint_data.unit_id
	local end_t = waypoint_data.end_t
	if end_t and end_t ~= 0 then
		local int = math.floor(end_t)
		local dec = end_t - int
		timer_string = string.format("%i:%i",int,dec * 100)
	else
		timer_string = "0"
	end
	local pos = waypoint_data.position
	if waypoint_type == self.WAYPOINT_TYPES.POSITION then
		sync_string = string.format("%i;%i;%i;%s;%i;%i;%i",
			waypoint_type,
			label_index,
			icon_index,
			timer_string,
			pos.x,
			pos.y,
			pos.z
		)
	elseif waypoint_type == self.WAYPOINT_TYPES.UNIT then
		sync_string = string.format("%i;%i;%i;%i;%i;%i;%i;%i",
			waypoint_type,
			label_index,
			icon_index,
			timer_string,
			pos.x,
			pos.y,
			pos.z,
			unit_id
		)
	end
	
	if sync_string then
--		self:Log(sync_string) --!

		local API_VERSION = self.API_VERSION
		for _,peer in pairs(managers.network:session():peers()) do 
			if peer._quickchat_version == API_VERSION then
				LuaNetworking:SendToPeer(peer:id(),self.SYNC_MESSAGE_WAYPOINT_ADD,sync_string)
			end
		end
	end
end

function QuickChat:ReceiveWaypoint(peer_id,message_string)
	local data = string.split(message_string,";")
	if data then
		local to_int = function(n)
			local _n = n and tonumber(n)
			if _n then 
				return math.floor(_n)
			end
			return 0
		end
		
		local waypoint_type = to_int(data[1])
		local waypoint_label = to_int(data[2])
		local waypoint_icon = to_int(data[3])
		local _timer_data = data[4]
		local start_t = TimerManager:game():time() --not exactly the same as original send time due to latency, but close enough; 
		local end_t = nil --end_t should be properly synced, on the other hand
		if _timer_data ~= "0" and string.find(_timer_data,":") then
			local timer_data = string.split(_timer_data,":")
			--circumvent issue with regional "." vs "," difference for post-decimal values
			end_t = to_int(timer_data[1]) + to_int(timer_data[2]) / 100
		end
		local position = Vector3(to_int(data[5]),to_int(data[6]),to_int(data[7]))
		
		if waypoint_type == self.WAYPOINT_TYPES.POSITION then
			self:_AddWaypoint(peer_id,{
				waypoint_type = waypoint_type,
				label_index = waypoint_label,
				icon_index = waypoint_icon,
				start_t = start_t,
				end_t = end_t,
				position = position,
				unit = unit_result
			})
		elseif type_id == self.WAYPOINT_TYPES.UNIT then
			local unit_id = to_int(data[8])
			local unit_result
			if unit_id > 0 then
				--cheat the networking a little bit; 
				--syncing units directly without using the built-in network extensions is a challenge
				--but hypothetically, most units should probably be well within this distance at the time of receiving the waypoint message
				local near_units = World:find_units_quick("sphere",position,self.WAYPOINT_RAYCAST_DISTANCE / 2,1)
				for _,unit in pairs(near_units) do 
					if unit:id() == unit_id then
						unit_result = unit
						break
					end
				end
			else
				--bad data
				return
			end
			self:_AddWaypoint(peer_id,{
				waypoint_type = waypoint_type,
				label_index = waypoint_label,
				icon_index = waypoint_icon,
				start_t = start_t,
				end_t = end_t,
				position = position,
				unit = unit_result
			})
		end
	end
end

function QuickChat:_AddWaypoint(peer_id,waypoint_data)
	local label_index = waypoint_data.label_index
	local icon_index = waypoint_data.icon_index
	local end_t = waypoint_data.end_t
	local peer_color = tweak_data.chat_colors[peer_id]
	local parent_panel = self._parent_panel
	if alive(parent_panel) then 
		
		local waypoint_panel = parent_panel:panel({
			name = "panel",
			w = 100,
			h = 100,
			valign = "grow",
			halign = "grow",
			visible = true,
			alpha = 1,
			layer = 1
		})
		local c_x,c_y = waypoint_panel:center()
		
		local debug_rect = waypoint_panel:rect({
			name="",
			color=Color.red,
			valign="grow",
			halign="grow",
			alpha=0.2,
			visible = false
		})
		
		
		local texture,texture_rect = self:GetIconDataByIndex(icon_index)
		local icon_visible = texture and true or false
		local label_id = label_index and self._label_presets[label_index]
		local label_text = label_id and managers.localization:text(label_id)
		
		local icon_size = 24
		local arrow_size = 16
		local label_font_size = 24
		local arrow_texture,arrow_texture_rect = self:GetIconDataByIndex(152)
		local arrow = waypoint_panel:bitmap({
			name = "arrow",
			texture = arrow_texture,--"guis/textures/pd2/progress_reload",
			texture_rect = arrow_texture_rect,
			w = arrow_size,
			h = arrow_size,
			valign = "grow",
			halign = "grow",
			color = peer_color,
			visible = true,
			layer = 4
		})
		arrow:set_center(c_x,c_y)
		local arrow_ghost = waypoint_panel:bitmap({
			name = "arrow_ghost",
			texture = arrow_texture,
			texture_rect = arrow_texture_rect,
			w = arrow_size,
			h = arrow_size,
			x = arrow:x(),
			y = arrow:y(),
--			valign = "grow",
--			halign = "grow",
			color = peer_color,
			alpha = 0,
			visible = true,
			layer = 5
		})
		
		local icon = waypoint_panel:bitmap({
			name = "icon",
			texture = texture,
			texture_rect = texture_rect,
			w = icon_size,
			h = icon_size,
			color = Color.white,
			visible = icon_visible,
			layer = 1
		})
		icon:set_bottom(arrow:y())
		icon:set_center_x(c_x)
		
		local font = "fonts/font_medium_shadow_mf"
		local label = waypoint_panel:text({
			name = "label",
			text = label_text or "LABELLINE",
			font = font,
			font_size = label_font_size,
			align = "center",
			vertical = "top",
			color = peer_color,
			layer = 3
		})
		if not icon_visible then
			label:set_y(arrow:y() - label_font_size)
		end
		
		--timer or distance
		local desc = waypoint_panel:text({ 
			name = "desc",
			text = "TEST2",
			font = font,
			font_size = 16,
			y = arrow:bottom() + 4,
			align = "center",
			vertical = "top",
			color = peer_color,
			layer = 3
		})
		local peer_waypoints = QuickChat._synced_waypoints[peer_id]
		local current_num_waypoints = #peer_waypoints
		local max_num_waypoints = self:GetMaxNumWaypoints()
		if current_num_waypoints >= max_num_waypoints then
			self:RemoveWaypoint(peer_id,1)
		end
		local new_waypoint = {
			panel = waypoint_panel,
			icon = icon,
			label = label,
			desc = desc,
			arrow = arrow,
			arrow_ghost = arrow_ghost,
			start_t = waypoint_data.start_t or 0,
			end_t = end_t,
			state = "onscreen",
			animate_in_duration = _G.sdfasd or 3,
			waypoint_type = waypoint_data.waypoint_type,
			unit = waypoint_data.unit,
			position = waypoint_data.position
--			params = waypoint_data
		}
--		waypoint_panel:set_size(1,1)
		table.insert(peer_waypoints,#peer_waypoints + 1,new_waypoint)
--				local waypoint_index = 1 + ((current_num_waypoints + 1) % max_num_waypoints)
	end
end

function QuickChat:RemoveWaypoint(peer_id,waypoint_index)
	local peer_waypoints = peer_id and self._synced_waypoints[peer_id]
	if peer_waypoints and waypoint_index then
		local waypoint_data = table.remove(peer_waypoints,waypoint_index)
		if waypoint_data and alive(waypoint_data.panel) then
			waypoint_data.panel:parent():remove(waypoint_data.panel)
		end
	end
end

function QuickChat:OnPeerDisconnected(peer_id)
	if peer_id then
		self:DisposeWaypoints(peer_id)
	end
end

function QuickChat:DisposeWaypoints(peer_id)
	local peer_waypoints = peer_id and self._synced_waypoints[peer_id]
	if peer_waypoints then
		for waypoint_index=#peer_waypoints,1,-1 do
			local waypoint_data = table.remove(peer_waypoints,waypoint_index)
			if alive(waypoint_data.panel) then
				waypoint_data.panel:parent():remove(waypoint_data.panel)
			end
		end
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
	if peer_id then 
		local session = managers.network:session()
		local peer = session and session:peer(peer_id)
		if peer then 
			return peer._quickchat_version
		end
	end
end

function QuickChat:SendPresetMessage(preset_text_index)
	local preset_text = preset_text_index and self._message_presets[preset_text_index]
	if preset_text then
		if managers.chat then
			local network_mgr = managers.network
			if network_mgr then
				local session = network_mgr:session()
				if session then 
					local local_peer = session:local_peer()
					local username = network_mgr.account:username()
					local text_localized = managers.localization:text(preset_text)
					for _,peer in pairs(session:peers()) do 
						local quickchat_version = peer._quickchat_version 
						
						--if the QC API changes in the future, outbound messages will be reformatted here
						if quickchat_version == self.API_VERSION then
							--v2
							LuaNetworking:SendToPeer(peer:id(),self.SYNC_MESSAGE_PRESET,preset_text_index)
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
	else
		self:Log("Error: SendPresetMessage(" .. tostring(preset_text_index) .. ") bad preset index!")
		return
	end
end

function QuickChat:ReceivePresetMessage(peer_id,preset_text_index)
	local preset_text = preset_text_index and self._message_presets[preset_text_index]
	if preset_text then
		if managers.chat then
			local network_mgr = managers.network
			if network_mgr then
				local session = network_mgr:session()
				if session then
					local peer = session:peer()
					if peer then
						local peer_color = tweak_data.chat_colors[peer_id]
						local username = peer:name()
						local text_localized = managers.localization:text(preset_text)
						--local quickchat_version = peer._quickchat_version
						--if the QC API changes in the future, inbound messages will be reformatted here
						managers.chat:_receive_message(ChatManager.GAME,username,text_localized,peer_color)
					end
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
	
	self:UpdateWaypoints(t,dt)
end


local mrot_y = mrotation.y
local mvec3_dot = mvector3.dot
local mvec3_normalize = mvector3.normalize

local tmp_cam_fwd = Vector3()
function QuickChat:UpdateWaypoints(t,dt)	
	local game_t = TimerManager:game():time()
	local viewport_cam = managers.viewport:get_current_camera()
	local ws = self._ws
	if not viewport_cam then 
		return
	end
	local parent_panel = self._parent_panel
	if not alive(parent_panel) then
		return
	end
	
	local pc_x,pc_y = parent_panel:center()
	local pw,ph = parent_panel:size()
	local outer_clamp_x_min = 0 + 100/2
	local outer_clamp_x_max = pw - (100/2)
	local outer_clamp_y_min = 0 + 100/2
	local outer_clamp_y_max = ph - (100/2)
	local camera_position = managers.viewport:get_current_camera_position()
	local camera_rotation = managers.viewport:get_current_camera_rotation()
	
	mrot_y(camera_rotation,tmp_cam_fwd)
--	local player = managers.player:local_player()
	for peer_id,peer_data in pairs(self._synced_waypoints) do 
		for waypoint_id=#peer_data,1,-1 do 
			
			local waypoint_data = peer_data[waypoint_id]
			local is_valid = true
			local end_t = waypoint_data.end_t
			local wp_position = waypoint_data.position
			if end_t then
				local remaining_t = end_t - game_t
				if remaining_t <= 0 then
					--expire
					is_valid = false
					self:RemoveWaypoint(peer_id,waypoint_id)
				else
					waypoint_data.desc:set_text(string.format("%0.1f",remaining_t))
				end
			else
				local waypoint_type = waypoint_data.waypoint_type
				if waypoint_type == self.WAYPOINT_TYPES.UNIT then
					local unit = waypoint_data.unit
					if alive(unit) then
						local oobb = unit:oobb()
						wp_position = oobb and oobb:center() or unit:position() or wp_position
					else
						--expire (unit dead/despawned or otherwise invalid)
						self:RemoveWaypoint(peer_id,waypoint_id)
						is_valid = false
					end
				else
					--is position based (wp_position is already set by default)
				end
			end
			
			if is_valid then
				local panel_pos = ws:world_to_screen(viewport_cam,wp_position)
				local distance = mvec3_distance(camera_position,wp_position)
				local panel_x,panel_y = panel_pos.x,panel_pos.y
				
				
				local direction = wp_position - camera_position
				mvec3_normalize(direction)
				local dot = mvec3_dot(tmp_cam_fwd,direction)
				
				--[[
				Console:SetTracker(dot,1)
				Console:SetTracker(math.X:angle(tmp_cam_fwd,2))
				Console:SetTracker(math.sign(tmp_cam_fwd.y),3)
				Console:SetTracker(math.X:angle(tmp_cam_fwd) * math.sign(tmp_cam_fwd.y),4)
				--]]
				
				local hud_direction
				local c_x = panel_x - pc_x
				local c_y = panel_y - pc_y
				local new_waypoint_state
				local arrow = waypoint_data.arrow
				
				if dot < 0 or parent_panel:outside(panel_x - outer_clamp_x_min,panel_y - outer_clamp_y_min) or parent_panel:outside(panel_x + outer_clamp_x_min,panel_y + outer_clamp_y_min) then
					new_waypoint_state = "offscreen"
					
					local x_r = math.clamp(panel_x,0,pw) / pw
					local y_r = math.clamp(panel_y,0,ph) / ph

					if c_x ~= 0 or c_y ~= 0 then
						hud_direction = math.atan(c_y/c_x)
						if c_x < 0 then
							hud_direction = hud_direction + 180
						end
--						Console:SetTracker(hud_direction,2)
					else
						hud_direction = 0
--						Console:SetTracker("blergh!",2)
					end
					
					panel_x = pc_x + (outer_clamp_x_max * math.cos(hud_direction) / 2)
					panel_y = pc_y + (outer_clamp_y_max * math.sin(hud_direction) / 2)
				else
					new_waypoint_state = "onscreen"
					if c_x ~= 0 or c_y ~= 0 then
						hud_direction = math.atan(c_y/c_x)
						if c_x > 0 then
							hud_direction = hud_direction + 180
						end
					end
					
--					Console:SetTracker(hud_direction,2)
				end
				if new_waypoint_state == "offscreen" then
					arrow:set_rotation(hud_direction)
				end
				if waypoint_data.animate_in_duration then
					local arrow_ghost = waypoint_data.arrow_ghost
					if waypoint_data.animate_in_duration > 0 then
						local start_t = waypoint_data.start_t
						local arrow_ghost_size = 16
						local duration = 1
						local pulse_t = 1 - (math.cos(((game_t - start_t) * 180/duration) % 180)+1) / 2
	--					local pulse_t = math.sin((game_t- * speed * 90) % 90)
						local size_scaled = arrow_ghost_size * (1 + pulse_t)
	--					Console:SetTracker(pulse_t,1)
	--					Console:SetTracker(scaled,2)
						arrow_ghost:set_size(size_scaled,size_scaled)
						arrow_ghost:set_alpha(1 - pulse_t)
						arrow_ghost:set_center(waypoint_data.panel:w()/2,waypoint_data.panel:h()/2)
						
						waypoint_data.animate_in_duration = waypoint_data.animate_in_duration - dt
					else
						arrow_ghost:hide()
						waypoint_data.animate_in_duration = nil
					end
				end
				if new_waypoint_state ~= waypoint_data.state then
					local arrow_texture,arrow_texture_rect
					if new_waypoint_state == "offscreen" then
						arrow_texture,arrow_texture_rect = self:GetIconDataByIndex(24) --arrow
					elseif new_waypoint_state == "onscreen" then
						arrow:set_rotation(0)
						arrow_texture,arrow_texture_rect = self:GetIconDataByIndex(152) --dot
					end
					arrow:set_image(arrow_texture,unpack(arrow_texture_rect or {}))
					waypoint_data.state = new_waypoint_state
				end
				
				waypoint_data.panel:set_center(panel_x,panel_y)
				waypoint_data.desc:set_text(string.format("%0.1fm",distance / 100))
			end
		end
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

Hooks:Add("LocalizationManagerPostInit","QuickChat_LocalizationManagerPostInit",function(loc)
	if not BeardLib then 
		loc:load_localization_file(QuickChat._mod_path .. "loc/english.json")
	end
end)

Hooks:Add("NetworkReceivedData","QuickChat_NetworkReceivedData",function(sender, message_id, message_body)
	if message_id == QuickChat.SYNC_MESSAGE_PRESET then
		QuickChat:ReceivePresetMessage(sender,message_body)
	elseif message_id == QuickChat.SYNC_MESSAGE_WAYPOINT_ADD then
		QuickChat:ReceiveWaypoint(sender,message_body)
	elseif message_id == QuickChat.SYNC_MESSAGE_REGISTER then
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