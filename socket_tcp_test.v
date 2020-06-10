module net

fn echo() ? {
	// tcpbin echo server
	c := dial_tcp('52.20.16.20', 30000)?
	defer { c.close()? }

	data := 'Hello from emily33901.socket!'
	as_bytes := data.bytes()

	c.write(as_bytes)?

	buf := []byte{ len: 100, init: 0 }

	read := c.read(buf)?

	assert read == data.len

	for i := 0; i < read; i++ {
		assert buf[i] == data[i]
	}

	return none
}

fn tcp_test() {
	echo() or {
		println(err)
		assert false
	}
}