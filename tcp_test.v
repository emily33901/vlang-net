module net

fn handle_conn(c TcpConn) {
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

fn echo_server(l TcpListener) ? {
	for {
		new_conn := l.accept()?
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

fn test_tcp() {
	// Make sure that net is inited
	// this is probably a V bug becuase this isnt necessary in a real program
	init()
	l := listen_tcp(30000) or {
		println(err)
		assert false
		panic('')
	}

	go echo_server(l)
	echo() or {
		println(err)
		assert false
	}

	l.close() or {
		assert false
		panic('')
	}
}