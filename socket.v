module net

pub enum SocketType {
	udp = C.SOCK_DGRAM
	tcp = C.SOCK_STREAM
}

pub enum SocketFamily {
	inet = C. AF_INET
}