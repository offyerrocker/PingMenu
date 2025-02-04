-- fix a couple of minor issues, including a crash at:
-- _reload_item()  core/lib/managers/menu/reference_renderer/coremenunodegui.lua:321  

core:module("CoreMenuNodeGui")
core:import("CoreUnit")

function NodeGui:_reload_item(item)
	local row_item = self:row_item(item)
	local params = item:parameters()
	local item_text = "" -- fixed missing local declaration (bad scope), added initialize with fallback to avoid crashing

--	local Print = _G.Print or
--		function(...)
--			if _G.log then
--				_G.log(tostring(...))
--			end
--		end
		
	if params.text_id then
		if self.localize_strings and params.localize ~= false and params.localize ~= "false" then
			item_text = managers.localization:text(params.text_id)
		else
			item_text = params.text_id
		end
	end
	if row_item then
		row_item.text = item_text
		if alive(row_item.gui_panel) and row_item.gui_panel.set_text then -- added alive sanity check on gui panel, in case a caller tries to refresh an item with gui objects that have been removed
			row_item.gui_panel:set_text(row_item.to_upper and utf8.to_upper(row_item.text) or row_item.text)
			row_item.gui_panel:set_color(row_item.color)
		else
			--Print("Obj is not alive or set_text method is not defined",row_item.gui_panel)
		end
	end
end
