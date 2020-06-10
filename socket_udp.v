module net

pub struct UdpConn {
	sock UdpSocket
}

pub struct UdpListener {
	sock UdpSocket
}

struct UdpSocket {
	handle int
}