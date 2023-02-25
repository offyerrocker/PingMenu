Hooks:PostHook(ClientNetworkSession,"on_peer_synched","QuickChat_ClientNetworkSession_onpeersynched",function(self,peer_id,...)
	QuickChat:SendSyncPeerVersionToAll()
end)
