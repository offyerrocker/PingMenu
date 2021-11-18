Hooks:PostHook(MenuNodeGui,"_setup_item_rows","tacticallean_checkforholdthekeydependency",function(self,...)
    if not (_G.RadialMouseMenu or self._HAS_SHOWN_RADIALMOUSEMENU_MISSING_PROMPT) then
        QuickMenu:new(
           managers.localization:text("menu_missing_rmm_prompt_title"),
           managers.localization:text("menu_missing_rmm_prompt_desc"),
		   {
                {
                    text = managers.localization:text("menu_ok"),
                    is_cancel_button = true
                }
            },
            true
        )
		self._HAS_SHOWN_RADIALMOUSEMENU_MISSING_PROMPT = true
	end
end)