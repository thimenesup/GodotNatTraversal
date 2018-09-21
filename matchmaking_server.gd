extends NAT_Traversal

class_name MatchmakingServer


var matches = [] #Array of MatchmakingMatch


func __create_match(lan_ip = "192.168.1.1"): #Called by clients, Executed on server
	print("Creating match")
	var mmatch : MatchmakingMatch = MatchmakingMatch.new()
	mmatch.peer = last_peer
	mmatch.host_lan_ip = lan_ip
	
	mmatch.host_ip = get_peer_ip(last_peer)
	mmatch.host_port = get_peer_port(last_peer)
	
	matches.append(mmatch)

func __request_join(lan_ip = "192.168.1.1"): #Called by clients, Executed on server
	print("Join request")
	if matches.size() > 0:
		var mmatch = matches[0]
		
		if lan_ip == mmatch.host_lan_ip:
			send_rpc(last_peer,"join_to",[mmatch.host_lan_ip,mmatch.host_port])
		else:
			send_rpc(last_peer,"join_to",[mmatch.host_ip,mmatch.host_port])
		
		var client_ip = get_peer_ip(last_peer)
		var client_port = get_peer_port(last_peer)
		
		if last_peer is PacketPeerUDP: #Handshake only makes sense for UDP
			last_peer.set_dest_address(mmatch.host_ip,mmatch.host_port)
			send_rpc(last_peer,"handshake",[client_ip,client_port])


func __handshake(ip,port): #Called by server, Executed on clients
	last_peer.set_dest_address(ip,port)
	for i in range(3):
		send_rpc(last_peer,"msg",["HANDSHAKE"])


func __join_to(ip,port): #Called by server, Executed on clients
	print("Joining %s:%s" % [ip,port])
	var net = NetworkedMultiplayerENet.new()
	net.create_client(ip,5050) #Ignore port for now, we always use 5050 for hosting
	get_tree().network_peer = net
