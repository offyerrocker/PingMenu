Hooks:PostHook(MenuNodeGui,"_setup_item_rows","tacticallean_checkforholdthekeydependency",function(self,...)
    if not self._HAS_SHOWN_PING_DEPENDENCIES_MISSING_PROMPT then
		local function loc(text)
			return managers.localization:text(text)
		end
		local missing_any = false
		local title = loc("menu_missing_dependencies_prompt_title")
		local desc = loc("menu_missing_dependencies_prompt_desc")
		for mod_id,dependency in pairs(QuickChat._dependencies) do 
			if type(dependency.check_has_dependency) == "function" and not dependency.check_has_dependency() then 
				missing_any = true
				local new_mod_string = loc("menu_missing_dependency_desc")
				new_mod_string = string.gsub("$NAME",loc(dependency_data.name_id))
				new_mod_string = string.gsub("$DESC",loc(dependency_data.desc_id))
				new_mod_string = string.gsub("$LINK",dependency_data.link)
			end
		end
		if missing_any then 
			QuickMenu:new(
				title,
				desc,
			   {
					{
						text = loc("menu_ok"),
						is_cancel_button = true
					}
				},
				true
			)
		end
		self._HAS_SHOWN_PING_DEPENDENCIES_MISSING_PROMPT = true
	end
end)