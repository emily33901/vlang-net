module main

import emily33901.net
import os
import time

fn handle_conn(c net.TcpConn) {
	buf := []byte{ len: 100, init: 0 }
	for {
		read := c.read_into(buf) or {
			match errcode {
				// TODO: replace when constant eval bug fixed
				net.err_read_timed_out_code {
					continue
				}
				else {
					println('Server: connection dropped $err')
				}
			}
			return
		}

		c.write(buf[..read]) or {
			println('Server: connection dropped $err')
			return
		}
	}
}

fn echo_server(l net.TcpListener) ? {
	for {
		new_conn := l.accept() or {
			time.sleep(1)
			continue
		}
		go handle_conn(new_conn)
	}

	return none
}

fn echo(c net.TcpConn) ? {
	println('Type and see it echoed by a local listen server!')

	for {
		data := os.get_line()
		as_bytes := data.bytes()
		c.write(as_bytes)?

		if data.len == 0 { continue }

		mut read := 0
		mut buf := []byte{ len: as_bytes.len+1, init: 0 }

		for {
			read = c.read_into(mut buf) or {
				match errcode {
					// TODO: replace when constant eval bug fixed
					9 {
						continue
					}
					else {}
				}
				return none
			}
			break
		}
		assert read == as_bytes.len

		println('> ${string(buf)}')
	}

	return none
}

fn main() {
	// Make sure that the listen port exists first
	// probably not necessary but ya know
	l := net.listen_tcp(30000)?

	go echo_server(l)

	c := net.dial_tcp('127.0.0.1:30000')?
	defer { c.close()? }

	echo(c)?

	l.close() or {
		assert false
		panic('')
	}
}