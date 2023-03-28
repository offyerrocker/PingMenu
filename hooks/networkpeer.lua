Hooks:PreHook(NetworkPeer,"destroy","qc_on_peer_removed",function(self)
	local peer_id = self:id()
--	QuickChat:Log("QuickChat: Disconnected peer_id " .. tostring(peer_id))
	if QuickChat then
		QuickChat:OnPeerDisconnected(peer_id)
	end
end)