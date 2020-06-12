module net

pub struct TcpConn {
	sock TcpSocket
}

pub fn dial_tcp(address string) ?TcpConn {
	s := new_tcp_socket()?
	s.connect(address)?

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
pub fn (c TcpConn) read(mut buf []byte) ?int {
	return socket_error(C.recv(c.sock.handle, buf.data, buf.len, 0))
}

pub struct TcpListener {
	sock TcpSocket
}

pub fn listen_tcp(port int) ?TcpListener {
	s := new_tcp_socket()?
	if port > u16(-1) {
		return err_invalid_port
	}

	mut addr := C.sockaddr_in{}
	addr.sin_family = SocketFamily.inet
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

pub fn (l TcpListener) accept() ?TcpConn {
	addr := C.sockaddr_storage{}
	unsafe {
		C.memset(&addr, 0, sizeof(C.sockaddr_storage))
	}
	size := sizeof(C.sockaddr_storage)

	// cast to correct type
	sock_addr := &C.sockaddr(&addr)
	new_handle := C.accept(l.sock.handle, sock_addr, &size)
	
	if new_handle == -1 {
		return none
	}

	new_sock := TcpSocket {
		handle: new_handle
	}

	return TcpConn{sock: new_sock}
}
pub fn (c TcpListener) close() ? {
	c.sock.close()?
	return none
}

struct TcpSocket {
pub:
	handle int
}

fn new_tcp_socket() ?TcpSocket {
	sockfd := C.socket(SocketFamily.inet, SocketType.tcp, 0)

	if sockfd == -1 {
		socket_error(sockfd)?
	}

	s := TcpSocket {
		handle: sockfd
	}
	s.set_option_bool(.reuse_addr, true)?
	return s
}

pub fn (s TcpSocket) set_option_bool(opt SocketOption, value bool) ? {
	// TODO reenable when this `in` operation works again
	// if opt !in opts_can_set {
	// 	return err_option_not_settable
	// }

	// if opt !in opts_bool {
	// 	return err_option_wrong_type
	// }

	socket_error(C.setsockopt(s.handle, C.SOL_SOCKET, int(opt), &value, sizeof(bool)))?

	return none
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

fn (s TcpSocket) connect(a string) ? {
	addr := resolve_addr(a, .inet, .tcp)?

	socket_error(C.connect(s.handle, addr.info.ai_addr, addr.info.ai_addrlen))?

	return none
}