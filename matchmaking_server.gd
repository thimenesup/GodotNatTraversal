extends NAT_Traversal

class_name MatchmakingServer


var matches = [] #Array of MatchmakingMatch


func __create_match(lan_ip = "192.168.1.1",host_port = 5050): #Called by clients, Executed on server
	var mmatch : MatchmakingMatch = MatchmakingMatch.new()
	mmatch.peer = last_peer
	mmatch.host_lan_ip = lan_ip
	
	mmatch.host_ip = get_peer_ip(last_peer)
	mmatch.host_port = get_peer_port(last_peer)
	
	print("Creating match %s:%s" % [mmatch.host_ip,host_port])
	
	matches.append(mmatch)

func __request_join(lan_ip = "192.168.1.1"): #Called by clients, Executed on server
	var client_ip = get_peer_ip(last_peer)
	var client_port = get_peer_port(last_peer)
	print("Join request from %s:%s" % [client_ip,client_port])
	if matches.size() > 0:
		var mmatch = matches[0]
		
		if lan_ip == mmatch.host_lan_ip and not lan_ip.begins_with("127"):
			send_rpc(last_peer,"join_to",[mmatch.host_lan_ip,mmatch.host_port])
		else:
			send_rpc(last_peer,"join_to",[mmatch.host_ip,mmatch.host_port])
		
		
		if last_peer is PacketPeerUDP: 
			last_peer.set_dest_address(mmatch.host_ip,mmatch.host_port)
			send_rpc(last_peer,"handshake",[client_ip,client_port])
		else: #We are using TCP
			send_rpc(mmatch.peer,"handshake",[client_ip,client_port])


func __handshake(ip,port): #Called by server, Executed on clients
	print("Performing handshake with %s:%s" % [ip,port])
	var peer = null
	if last_peer is PacketPeerUDP:
		last_peer.set_dest_address(ip,port)
		peer = last_peer
	else: #We are using TCP, we will still send the handshake using UDP since its what the HLAPI uses it
		peer = PacketPeerUDP.new()
		peer.set_dest_address(ip,port)
	for i in range(3):
		send_rpc(peer,"msg",["HANDSHAKE"])


func __join_to(ip,port): #Called by server, Executed on clients
	print("Joining %s:5050" % ip)#print("Joining %s:%s" % [ip,port])
	var net = NetworkedMultiplayerENet.new()
	net.create_client(ip,5050)
	get_tree().network_peer = net
