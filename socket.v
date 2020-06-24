module net

enum Select {
	read write except
}

pub enum SocketType {
	udp = C.SOCK_DGRAM
	tcp = C.SOCK_STREAM
}

pub enum SocketFamily {
	inet = C. AF_INET
}