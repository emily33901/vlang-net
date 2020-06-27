module net

pub struct Addr {
	addr C.sockaddr
	len int
	saddr string
	port u16
}

pub fn (a Addr) str() string {
	return a.saddr
}

pub fn resolve_addr(addr string, family SocketFamily, typ SocketType) ?Addr {
	address, port := split_address(addr)?

	mut hints := C.addrinfo{}
	hints.ai_family = family
	hints.ai_socktype = typ
	hints.ai_flags = C.AI_PASSIVE
	hints.ai_protocol = 0
	hints.ai_addrlen = 0
	hints.ai_canonname = C.NULL
	hints.ai_addr = C.NULL
	hints.ai_next = C.NULL
	info := &C.addrinfo(0)

	sport := '$port'

	// TODO this is not technically correct because socket_error will then
	// try to get the last errno which wont(?) be correct
	socket_error(0-C.getaddrinfo(address.str, sport.str, &hints, &info))?

	return Addr {
		addr: *info.ai_addr
		len: info.ai_addrlen
		saddr: addr
		port: port
	}
}