module main

import emily33901.net

fn echo(c net.TcpConn, data string) ?string {
	as_bytes := data.bytes()

	c.write(as_bytes)?

	buf := []byte{ len: 100, init: 0 }
	
	read := c.read(buf)?

	assert read == data.len

	for i := 0; i < read; i++ {
		assert buf[i] == data[i]
	}

	return buf[..read]
}

fn main() ? {
	// tcpbin echo server
	c := net.dial_tcp('52.20.16.20', 30000)?
	defer { c.close()? }

	for {
		line := get_line()
		result := echo(line)?
		println('"$result"')
	}

}