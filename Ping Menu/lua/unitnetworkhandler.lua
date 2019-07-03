if true then return end
Hooks:PostHook(UnitNetworkHandler,"sync_player_movement_state","pingmenu_syncpingunit",function(self,unit,state,down_time,unit_id_str,...)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if alive(unit) then 
		if state == PingMenu.id_unittagged then 
			PingMenu:log("tagged unit " .. unit .. " from player " .. sender)
		end
	end
end)


local orig_sync_player = UnitNetworkHandler.sync_player_movement_state
function UnitNetworkHandler:sync_player_movement_state(unit, state, down_time, unit_id_str,...) 



--i can't reverse engineer RPC stuff and make my own unitnetworkhandler functions so... guess i'll die
--instead, hijack this function. use "unit", since i can't/don't know how to pass a unit through BLT Lua Networking, and argument "state" as string of my choice, and the other fields i don't care about. 
--todo see if i can pass the current time for better repair sync?
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
--	PrintTable({unit,state,down_time,unit_id_str})
	if alive(unit) then --receive repair update status from host
		if state == "start_repair_eq_sentry" then --repair start/finish are controlled by host only, naturally
			unit:base():start_repairmode()
			return
		elseif state == "finish_repair_eq_sentry" then 
			unit:base():finish_repairmode()
			return
		end
	end
	return orig_sync_player(self,unit,state,down_time,unit_id_str,...)
end