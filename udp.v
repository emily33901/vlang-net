module net

pub struct UdpConn {
	sock UdpSocket
}

pub fn dial_udp(laddr, raddr string) ?UdpConn {
	sbase := new_udp_socket()?

	// Dont have to do this when its fixed
	// this just allows us to store this `none` optional in a struct
	resolve_wrapper := fn(raddr string) ?Addr {
		x :=  resolve_addr(raddr, .inet, .udp) or { return error('') }
		return x
	}

	local := resolve_addr(laddr, .inet, .udp)?

	sock := UdpSocket {
		handle: sbase.handle

		l: local
		r: resolve_wrapper(raddr)
	}

	return UdpConn {
		sock
	}
}

pub fn (c UdpConn) write(buf []byte) ? {
	remote := c.sock.remote() or {
		return err_no_udp_remote
	}

	c.write_to(remote, buf)

	// TODO maybe error not not enough bytes sent or similar?
	// We should provide some way of getting the max buffer size (or similarly: setting it)
}

// write_to blocks and writes the buf to the remote addr specified
pub fn (c UdpConn) write_to(addr Addr, buf []byte) ? {
	socket_error(C.sendto(c.sock.handle, buf.data, buf.len, 0, addr.info, sizeof(C.addrinfo)))?

	return none
}

// read_from reads from an address into buf up to buf.len returning the number of bytes read
pub fn (c UdpConn) read_from(addr Addr, mut buf []byte) ?(int, Addr) {
	addr_from := &C.addrinfo{}

	res := socket_error(C.recvfrom(c.sock.handle, buf.data, buf.len, 0, &addr_from, sizeof(C.addrinfo)))?

	return res, Addr {addr_from, addr_from.str()}
}

pub fn (c UdpConn) read(mut buf []byte) ?(int, Addr) {
	remote := c.sock.remote() or {
		return err_no_udp_remote
	}

	return c.read_from(remote, mut buf)
}

pub struct UdpListener {
	sock UdpSocket
}

struct UdpSocket {
	handle int

	l Addr
	r ?Addr
}

fn new_udp_socket() ?UdpSocket {
	sockfd := socket_error(C.socket(SocketFamily.inet, SocketType.udp, 0))?
			s := UdpSocket {
				handle: sockfd
			}
			s.set_option_bool(.reuse_addr, true)?
			return s
}

pub fn (s UdpSocket) remote() ?Addr {
	return s.r
}

pub fn (s UdpSocket) set_option_bool(opt SocketOption, value bool) ? {
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