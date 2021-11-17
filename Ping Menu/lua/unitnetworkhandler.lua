--[[
local orig_sync_player = UnitNetworkHandler.sync_player_movement_state
function UnitNetworkHandler:sync_player_movement_state(unit, state, down_time, unit_id_str,...) 

	if state == PingMenu.id_unittagged then 
		PingMenu:log("tagged unit " .. unit .. " from player " .. sender)
	end
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if alive(unit) then
		if state == "start_repair_eq_sentry" then
			unit:base():start_repairmode()
			return
		elseif state == "finish_repair_eq_sentry" then 
			unit:base():finish_repairmode()
			return
		end
	end
	return orig_sync_player(self,unit,state,down_time,unit_id_str,...)
end
--]]