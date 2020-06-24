module net

import time

pub struct UdpConn {
	sock UdpSocket

mut:
	has_write_deadline bool
	write_deadline time.Time

	has_read_deadline bool
	read_deadline time.Time

	read_timeout time.Duration
	write_timeout time.Duration
}

pub fn dial_udp(laddr, raddr string) ?UdpConn {
	sbase := new_udp_socket()?

	// Dont have to do this when its fixed
	// this just allows us to store this `none` optional in a struct
	resolve_wrapper := fn(raddr string) ?Addr {
		x :=  resolve_addr(raddr, .inet, .udp) or { return none }
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

	return c.write_to(remote, buf)
}

// write_to blocks and writes the buf to the remote addr specified
pub fn (c UdpConn) write_to(addr Addr, buf []byte) ? {
	res := C.sendto(c.sock.handle, buf.data, buf.len, 0, addr.info, sizeof(C.addrinfo))

	if res >= 0 {
		return none
	}

	code := error_code()
	match code {
		error_ewouldblock {
			c.wait_for_write()?
			socket_error(C.sendto(c.sock.handle, buf.data, buf.len, 0, addr.info, sizeof(C.addrinfo)))?
		}
		else {
			wrap_error(code)?
		}
	}

	// TODO maybe error not not enough bytes sent or similar?
	// We should provide some way of getting the max buffer size (or similarly: setting it)
	return none
}

// read_into reads from the socket into buf up to buf.len returning the number of bytes read
pub fn (c UdpConn) read_into(mut buf []byte) ?(int, Addr) {
	mut addr_from := C.addrinfo{}
	len := sizeof(C.addrinfo)

	res := C.recvfrom(c.sock.handle, buf.data, buf.len, C.MSG_WAITALL, &addr_from, &len)

	if res >= 0 {
		return res, Addr {&addr_from, addr_from.str()}
	}

	code := error_code()
	match code {
		error_ewouldblock {
			c.wait_for_read()?
			res2 := socket_error(C.recvfrom(c.sock.handle, buf.data, buf.len, C.MSG_WAITALL, &addr_from, &len))?
			return res2, Addr {&addr_from, addr_from.str()}
		}
		else {
			wrap_error(code)?
		}
	}
}

pub fn (c UdpConn) read() ?([]byte, Addr) {
	buf := []byte { len: 1024 }
	read, addr := c.read_into(mut buf)?
	return buf[..read], addr
}

pub fn (c UdpConn) read_deadline() ?time.Time {
	if c.read_deadline.unix == 0 {
		return c.read_deadline
	}
	return none
}

pub fn (mut c UdpConn) set_read_deadline(deadline time.Time) {
	if c.read_deadline.unix == 0 {
		c.has_read_deadline = true
		c.read_deadline = deadline
		return
	}
	c.has_read_deadline = false
}

pub fn (c UdpConn) write_deadline() ?time.Time {
	if c.write_deadline.unix == 0 {
		return c.write_deadline
	}
	return none
}

pub fn (mut c UdpConn) set_write_deadline(deadline time.Time) {
	if c.write_deadline.unix == 0 {
		c.has_write_deadline = true
		c.write_deadline = deadline
		return
	}
	c.has_write_deadline = false
}

pub fn (c UdpConn) read_timeout() time.Duration {
	return c.read_timeout
}

pub fn(mut c UdpConn) set_read_timeout(t time.Duration) {
	c.read_timeout = t
}

pub fn (c UdpConn) write_timeout() time.Duration {
	return c.write_timeout
}

pub fn (mut c UdpConn) set_write_timeout(t time.Duration) {
	c.write_timeout = t
}

pub fn (c UdpConn) wait_for_read() ? {
	return wait_for_read(c.sock.handle, c.read_deadline, c.read_timeout)
}

pub fn (c UdpConn) wait_for_write() ? {
	return wait_for_write(c.sock.handle, c.write_deadline, c.write_timeout)
}

pub fn (c UdpConn) close() ? {
	c.sock.close()?
	return none
}

pub fn listen_udp(port int) ?UdpConn {
	s := new_udp_socket()?

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

	return UdpConn {
		sock: s
	}
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
	$if windows {
		t := true
		socket_error(C.ioctlsocket(sockfd, fionbio, &t))?
	} $else {
		socket_error(C.fnctl(sockfd, C.F_SETFD, C.O_NONBLOCK))
	}
	
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

fn (s UdpSocket) close() ? {
	$if windows {
		C.shutdown(s.handle, C.SD_BOTH)
		socket_error(C.closesocket(s.handle))?
	} $else {
		C.shutdown(s.handle, C.SHUT_RDWR)
		socket_error(C.close(s.handle))?
	}
	return none
}

fn (s UdpSocket) @select(test Select, timeout time.Duration) ?bool {
	return @select(s.handle, test, timeout)
}