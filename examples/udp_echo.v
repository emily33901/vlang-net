module main

import time
import emily33901.net

fn handle_conn(mut c net.UdpConn) {
	// arbitrary timeouts to ensure that it doesnt
	// instantly throw its hands in the air and give up
	c.set_read_timeout(10 * time.second)
	c.set_write_timeout(10 * time.second)
	for {
		buf := []byte{ len: 100, init: 0 }
		read, addr := c.read_into(mut buf) or {
			continue
		}

		c.write_to(addr, buf[..read]) or {
			println('Server: connection dropped')
			return
		}
	}
}

fn echo_server(mut l net.UdpConn) {
	handle_conn(mut l)
}

fn echo() ? {
	mut c := net.dial_udp('127.0.0.1:30003', '127.0.0.1:30001')?
	defer { c.close() or { } }
	
	// arbitrary timeouts to ensure that it doesnt
	// instantly throw its hands in the air and give up
	c.set_read_timeout(10 * time.second)
	c.set_write_timeout(10 * time.second)

	data := 'Hello from emily33901.net!'
	as_bytes := data.bytes()

	c.write(as_bytes)?

	buf := []byte{ len: 100, init: 0 }
	read, addr := c.read_into(mut buf)?

	assert read == data.len
	assert addr.str() == '127.0.0.1:30001'

	for i := 0; i < read; i++ {
		assert buf[i] == data[i]
	}

	println('Got "${string(buf)}"')

	c.close()?

	return none
}

fn main() {
	// Make sure that net is inited
	// this is probably a V bug becuase this isnt necessary in a real program
	// net.init()
	l := net.listen_udp(30001) or {
		println(err)
		assert false
		panic('')
	}

	go echo_server(mut l)
	echo() or {
		println(err)
		assert false
	}

	l.close() or { }
}