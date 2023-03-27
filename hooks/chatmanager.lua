Hooks:PreHook(ChatManager,"mute_peer","qc_chatmgr_mute_peer",function(self,peer)
	if QuickChat and peer and peer:user_id() then
		QuickChat:DisposeWaypoints(peer:id())
	end
end)