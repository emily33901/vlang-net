module net

import time

fn handle_conn(mut c UdpConn) {
	// arbitrary timeouts to ensure that it doesnt
	// instantly throw its hands in the air and give up
	c.set_read_timeout(10 * time.second)
	c.set_write_timeout(10 * time.second)
	for {
		buf := []byte{ len: 100, init: 0 }
		read := c.read_into(mut buf) or {
			println('Server: connection dropped')
			return
		}

		c.write(buf[..read]) or {
			println('Server: connection dropped')
			return
		}
	}
}

fn echo_server(l UdpListener) ? {
	for {
		mut new_conn := l.accept()?
		go handle_conn(mut new_conn)
	}

	return none
}

fn echo() ? {
	mut c := dial_udp('127.0.0.1:30002', '127.0.0.1:30001')?
	defer { c.close() or {} }
	
	// arbitrary timeouts to ensure that it doesnt
	// instantly throw its hands in the air and give up
	c.set_read_timeout(10 * time.second)
	c.set_write_timeout(10 * time.second)

	data := 'Hello from emily33901.net!'
	as_bytes := data.bytes()

	c.write(as_bytes)?

	buf := []byte{ len: 100, init: 0 }
	read := c.read_into(mut buf)?

	assert read == data.len

	for i := 0; i < read; i++ {
		assert buf[i] == data[i]
	}

	println('Got "${string(buf)}"')

	return none
}

fn test_udp() {
	// Make sure that net is inited
	// this is probably a V bug becuase this isnt necessary in a real program
	init()
	l := listen_udp(30001) or {
		panic(err)
	}

	go echo_server(l)
	echo() or {
		panic(err)
	}

	l.close() or {
	}
}