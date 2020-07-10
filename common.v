module net

import time

// Shutdown shutsdown a socket and closes it
fn shutdown(handle int) ? {
	$if windows {
		C.shutdown(handle, C.SD_BOTH)
		socket_error(C.closesocket(handle))?
	} $else {
		C.shutdown(handle, C.SHUT_RDWR)
		socket_error(C.close(handle))?
	}

	return none
}

fn C.alloca() voidptr

// Select waits for an io operation (specified by parameter `test`) to be available
fn @select(handle int, test Select, timeout time.Duration) ?bool {
	set := C.fd_set{}

	C.FD_ZERO(&set)
	C.FD_SET(handle, &set)

	timeval_timeout := C.timeval{
		tv_sec: u64(0)
		tv_usec: u64(timeout.microseconds())
	}

	match test {
		.read {
			socket_error(C.@select(handle+1, &set, C.NULL, C.NULL, &timeval_timeout))?
		}
		.write {
			socket_error(C.@select(handle+1, C.NULL, &set, C.NULL, &timeval_timeout))?
		}
		.except {
			socket_error(C.@select(handle+1, C.NULL, C.NULL, &set, &timeval_timeout))?
		}
	}

	return C.FD_ISSET(handle, &set)
}

// wait_for_write waits for a write io operation to be available
fn wait_for_write(handle int, 
	deadline time.Time, 
	timeout time.Duration) ? {
	if deadline.unix == 0 {
		if timeout < 0 {
			return err_write_timed_out
		}
		ready := @select(handle, .write, timeout)?
		if ready {
			return none
		}
		return err_write_timed_out
	}
	// Convert the deadline into a timeout
	// and use that
	d_timeout := deadline.unix - time.now().unix
	if d_timeout < 0 {
		return err_write_timed_out
	}
	
	ready := @select(handle, .write, d_timeout)?
	if ready {
		return none
	}
	return err_write_timed_out
}

// wait_for_read waits for a read io operation to be available
fn wait_for_read(handle int, 
	deadline time.Time, 
	timeout time.Duration) ? {
	if deadline.unix == 0 {
		if timeout < 0 {
			return err_read_timed_out
		}
		ready :=  @select(handle, .read, timeout)?
		if ready {
			return none
		}
		return err_read_timed_out
	}
	// Convert the deadline into a timeout
	// and use that
	d_timeout := deadline.unix - time.now().unix
	if d_timeout < 0 {
		return err_read_timed_out
	}
	ready := @select(handle, .read, d_timeout)?
	if ready {
		return none
	}
	return err_read_timed_out
}