module net

import time

const (
	no_deadline = time.Time{unix: 0}
)

pub struct TcpConn {
	sock TcpSocket

mut:
	has_write_deadline bool
	write_deadline time.Time

	has_read_deadline bool
	read_deadline time.Time

	read_timeout time.Duration
	write_timeout time.Duration
}

pub fn dial_tcp(address string) ?TcpConn {
	s := new_tcp_socket()?
	s.connect(address)?

	return TcpConn {
		sock: s
		
		has_write_deadline: false
		has_read_deadline: false
		read_timeout: -1
		write_timeout: -1
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

pub fn (c TcpConn) read_into(mut buf []byte) ?int {
	res := C.recv(c.sock.handle, buf.data, buf.len, 0)

	if res >= 0 {
		return res
	}

	match error_code() {
		error_ewouldblock {
			c.wait_for_read()?
			// If we get here then we have something to read
			// So this should be non-recursive
			return c.read_into(mut buf)
		}
		else {
			return err_read_timed_out
		}
	}
}

pub fn (c TcpConn) read() ?[]byte {
	buf := []byte { len: 1024 }
	read := c.read_into(buf)?
	return buf[..read]
}

pub fn (c TcpConn) read_deadline() ?time.Time {
	if c.read_deadline.unix == 0 {
		return c.read_deadline
	}
	return none
}

pub fn (mut c TcpConn) set_read_deadline(deadline time.Time) {
	if c.read_deadline.unix == 0 {
		c.has_read_deadline = true
		c.read_deadline = deadline
		return
	}
	c.has_read_deadline = false
}

pub fn (c TcpConn) write_deadline() ?time.Time {
	if c.write_deadline.unix == 0 {
		return c.write_deadline
	}
	return none
}

pub fn (mut c TcpConn) set_write_deadline(deadline time.Time) {
	if c.write_deadline.unix == 0 {
		c.has_write_deadline = true
		c.write_deadline = deadline
		return
	}
	c.has_write_deadline = false
}

pub fn (c TcpConn) read_timeout() time.Duration {
	return c.read_timeout
}

pub fn(mut c TcpConn) set_read_timeout(t time.Duration) {
	c.read_timeout = t
}

pub fn (c TcpConn) write_timeout() time.Duration {
	return c.write_timeout
}

pub fn (mut c TcpConn) set_write_timeout(t time.Duration) {
	c.write_timeout = t
}

pub fn (c TcpConn) wait_for_read() ? {
	if !c.has_read_deadline {
		if c.read_timeout < 0 {
			return err_read_timed_out
		}
		ready :=  c.sock.@select(.read, c.read_timeout)?
		if ready {
			return none
		}
		return err_read_timed_out
	}
	// Convert the deadline into a timeout
	// and use that
	timeout := c.read_deadline.unix - time.now().unix
	if timeout < 0 {
		return err_read_timed_out
	}
	ready :=  c.sock.@select(.read, timeout)?
	if ready {
		return none
	}
	return err_read_timed_out
}

pub fn (c TcpConn) wait_for_write() ? {
	if !c.has_write_deadline {
		if c.write_timeout < 0 {
			return err_write_timed_out
		}
		ready := c.sock.@select(.write, c.write_timeout)?
		if ready {
			return none
		}
		return err_write_timed_out
	}
	// Convert the deadline into a timeout
	// and use that
	timeout := c.write_deadline.unix - time.now().unix
	if timeout < 0 {
		return err_write_timed_out
	}
	
	ready := c.sock.@select(.write, timeout)?
	if ready {
		return none
	}
	return err_write_timed_out
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

	$if windows {
		t := true
		socket_error(C.ioctlsocket(sockfd, fionbio, &t))?
	} $else {
		socket_error(C.fnctl(sockfd, C.F_SETFD, C.O_NONBLOCK))
	}

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

struct SelectResult {
	read bool
	write bool
	except bool
}

enum Select {
	read write except
}

fn (s TcpSocket) @select(test Select, timeout time.Duration) ?bool {
	set := C.fd_set{}
	C.FD_SET(s.handle, &set)

	seconds := timeout.milliseconds() / 1000
	microseconds := timeout - (seconds * time.second)

	timeval_timeout := C.timeval{
		tv_sec: u64(seconds)
		tv_usec: u64(microseconds)
	}

	match test {
		.read {
			socket_error(C.@select(0, &set, C.NULL, C.NULL, &timeval_timeout))?
		}
		.write {
			socket_error(C.@select(0, C.NULL, &set, C.NULL, &timeval_timeout))?
		}
		.except {
			socket_error(C.@select(0, C.NULL, C.NULL, &set, &timeval_timeout))?
		}
	}

	return set.fd_count == 1
}

const (
	connect_timeout = 20 * time.second
)

fn (s TcpSocket) connect(a string) ? {
	addr := resolve_addr(a, .inet, .tcp)?
	
	res := C.connect(s.handle, addr.info.ai_addr, addr.info.ai_addrlen)

	if res == 0 {
		return none
	}

	errcode := error_code()

	if errcode == error_ewouldblock {
		write_result := s.@select(.write, connect_timeout)?
		if write_result {
			// succeeded
			return none
		}

		except_result := s.@select(.except, connect_timeout)?
		if except_result {
			return err_connect_failed
		}

		// otherwise we timed out
		return err_connect_timed_out
	}

	return none
}