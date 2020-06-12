module main

import emily33901.net

fn handle_conn(c net.TcpConn) {
	for {
		buf := []byte{ len: 100, init: 0 }
		read := c.read(buf) or {
			println('Server: connection dropped')
			return
		}

		c.write(buf[..read]) or {
			println('Server: connection dropped')
			return
		}
	}
}

fn echo_server(l net.TcpListener) ? {
	for {
		new_conn := l.accept() or {
			// TODO sleep thread or yield or smth
			continue
		}
		go handle_conn(new_conn)
	}

	return none
}

fn echo() ? {
	c := net.dial_tcp('127.0.0.1:30000')?
	defer { c.close()? }

	data := 'Hello from emily33901.net!'
	as_bytes := data.bytes()

	c.write(as_bytes)?

	buf := []byte{ len: 100, init: 0 }
	read := c.read(buf)?

	assert read == data.len

	for i := 0; i < read; i++ {
		assert buf[i] == data[i]
	}

	println('Got "${string(buf)}"')

	return none
}

fn main() {
	// Make sure that the listen port exists first
	// probably not necessary but ya know
	l := net.listen_tcp(30000)?

	go echo_server(l)
	echo()?

	l.close() or {
		assert false
		panic('')
	}
}