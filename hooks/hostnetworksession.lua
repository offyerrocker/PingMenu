Hooks:PostHook(HostNetworkSession,"on_peer_sync_complete","QuickChat_HostNetworkSession_onpeersynccomplete",function(self,peer,peer_id)
	QuickChat:SendSyncPeerVersionToAll()
end)
