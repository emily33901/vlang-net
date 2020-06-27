module net

import time

fn echo_server(_c UdpConn) {
	mut c := _c
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

fn echo() ? {
	mut c := dial_udp('127.0.0.1:40003', '127.0.0.1:40001')?
	defer { c.close() or { } }
	
	// arbitrary timeouts to ensure that it doesnt
	// instantly throw its hands in the air and give up
	c.set_read_timeout(10 * time.second)
	c.set_write_timeout(10 * time.second)

	data := 'Hello from emily33901.net!'
	as_bytes := data.bytes()

	c.write(as_bytes)?

	buf := []byte{ len: 100, init: 0 }
	read, _ := c.read_into(mut buf)?

	assert read == data.len
	// assert addr.str() == '127.0.0.1:30001'

	for i := 0; i < read; i++ {
		assert buf[i] == data[i]
	}

	println('Got "${string(buf)}"')

	c.close()?

	return none
}

fn test_udp() {
	// Make sure that net is inited
	// this is probably a V bug becuase this isnt necessary in a real program
	init()
	l := net.listen_udp(40001) or {
		println(err)
		assert false
		panic('')
	}

	go echo_server(l)
	echo() or {
		println(err)
		assert false
	}

	l.close() or { }
}