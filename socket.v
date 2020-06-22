module net

pub enum SocketType {
	udp = C.SOCK_DGRAM
	tcp = C.SOCK_STREAM
}

pub enum SocketFamily {
	inet = C. AF_INET
}

const (
	default_read_timeout = 5
	default_write_timeout = 5
)