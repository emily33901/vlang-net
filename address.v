module net

pub struct Addr {
	info &C.addrinfo
	addr string
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

	// this uses '0-' because getaddrinfo returns 0 on success
	// and everything else is an error
	socket_error(C.getaddrinfo(address.str, sport.str, &hints, &info))?

	return Addr {
		info
		addr
	}
}