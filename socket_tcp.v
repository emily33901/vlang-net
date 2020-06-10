module net

pub struct TcpConn {
	sock TcpSocket
}

pub fn dial_tcp(address string, port int) ?TcpConn {
	if port > u16(-1) {
		return err_invalid_port
	}

	s := new_socket(.inet, .tcp)?

	mut hints := C.addrinfo{}
	hints.ai_family = s.family
	hints.ai_socktype = s.typ
	hints.ai_flags = C.AI_PASSIVE
	hints.ai_protocol = 0
	hints.ai_addrlen = 0
	hints.ai_canonname = C.NULL
	hints.ai_addr = C.NULL
	hints.ai_next = C.NULL
	info := &C.addrinfo(0)

	sport := '$port'
	info_res := C.getaddrinfo(address.str, sport.str, &hints, &info)

	socket_error(info_res)?

	res := C.connect(s.handle, info.ai_addr, info.ai_addrlen)

	socket_error(res)?

	return TcpConn {
		sock: s
	}
}

pub fn (c TcpConn) close() ? {
	c.sock.close()?
	return none
}

// write blocks and attempts to write all data
pub fn (c TcpConn) write(bytes []byte) ? {
	unsafe {
		mut ptr_base := byteptr(bytes.data)
		mut total_sent := 0

		for total_sent < bytes.len {
			ptr := ptr_base + total_sent
			remaining := bytes.len - total_sent
			sent := socket_error(C.send(c.sock.handle, ptr, remaining, msg_nosignal))?
			total_sent += sent
		}
	}
	return none
}

// read blocks and attempts to read bytes up to the size of arr
pub fn (c TcpConn) read(mut arr []byte) ?int {
	return socket_error(C.recv(c.sock.handle, arr.data, arr.len, 0))
}

pub struct TcpListener {
	sock TcpSocket
}

pub fn listen_tcp(port int) ?TcpListener {
	s := new_socket(.inet, .tcp)?
	if port > u16(-1) {
		return err_invalid_port
	}

	mut addr := C.sockaddr_in{}
	addr.sin_family = s.family
	addr.sin_port = C.htons(port)
	addr.sin_addr.s_addr = C.htonl(C.INADDR_ANY)
	size := sizeof(C.sockaddr_in)

	// cast to the correct type
	sockaddr := &C.sockaddr(&addr)

	socket_error(C.bind(s.handle, sockaddr, size))?
	socket_error(C.listen(s.handle, 128))?

	return TcpListener {
		sock: s
	}
}

pub fn (c TcpListener) close() ? {
	c.sock.close()?
	return none
}

struct TcpSocket {
pub:
	handle int

	family SocketFamily
	typ SocketType
}

pub fn (s TcpSocket) set_option_bool(opt SocketOption, value bool) ? {
	// if opt !in opts_can_set {
	// 	return err_option_not_settable
	// }

	// if opt !in opts_bool {
	// 	return err_option_wrong_type
	// }

	socket_error(C.setsockopt(s.handle, C.SOL_SOCKET, int(opt), &value, sizeof(bool)))?

	return none
}

// new_socket creates a socket with a given family and type
fn new_socket(family SocketFamily, typ SocketType) ?TcpSocket {
	sockfd := socket_error(C.socket(family, typ, 0))?

	if sockfd == -1 {
		return err_new_socket_failed
	}

	s := TcpSocket {
		handle: sockfd
		typ: typ
	}

	s.set_option_bool(.reuse_addr, true)?

	return s
}

fn (s TcpSocket) close() ? {
	$if windows {
		C.shutdown(s.handle, C.SD_BOTH)
		socket_error(C.closesocket(s.handle))?
	} $else {
		C.shutdown(s.handle, C.SHUT_RDWR)
		socket_error(C.close(s.handle))?
	}

	return none
}