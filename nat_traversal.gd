extends Node

class_name NAT_Traversal


var peers = []

var last_peer : PacketPeer = null

var tcp_server : TCP_Server = null


func setup_server(port : int,udp : bool):
	if udp:
		var peer = PacketPeerUDP.new()
		peer.listen(port)
		peers.append(peer)
	else: #TCP
		tcp_server = TCP_Server.new()
		tcp_server.listen(port)


func connect_to_server(ip : String,port : int,udp : bool):
	var peer = null
	if udp:
		peer = PacketPeerUDP.new()
		peer.set_dest_address(ip,port)
		peers.append(peer)
	else: #TCP
		peer = PacketPeerStream.new()
		var stream_peer = StreamPeerTCP.new()
		stream_peer.connect_to_host(ip,port)
		peer.stream_peer = stream_peer
		peers.append(peer)
	send_rpc(peer,"msg",["CONNECTION"])


func _process(delta):
	if tcp_server:
		for peer in peers:
			if not peer.stream_peer.is_connected_to_host():
				print("TCP Peer disconnected")
				peers.erase(peer)
		if tcp_server.is_connection_available():
			print("TCP Peer connected")
			var peer = PacketPeerStream.new()
			peer.stream_peer = tcp_server.take_connection()
			peers.append(peer)

	for peer in peers:
		while peer.get_available_packet_count() > 0:
			var packet = peer.get_var()
			if peer is PacketPeerUDP:
				peer.set_dest_address(peer.get_packet_ip(),peer.get_packet_port())
			last_peer = peer
			
			#Execute RPC
			callv("__" + packet[0],packet[1]) #Only call methods that start with __ for security


func send_rpc(peer : PacketPeer,method : String,args = []):
	var rpc = [method,args]
	peer.put_var(rpc)


func get_peer_ip(peer : PacketPeer) -> String:
	if peer is PacketPeerUDP:
		return peer.get_packet_ip()
	else:
		return peer.stream_peer.get_connected_host()

func get_peer_port(peer : PacketPeer) -> int:
	if peer is PacketPeerUDP:
		return peer.get_packet_port()
	else:
		return peer.stream_peer.get_connected_port()


func __msg(what):
	print(what)
