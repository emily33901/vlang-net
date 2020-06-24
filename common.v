module net

import time

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

fn @select(handle int, test Select, timeout time.Duration) ?bool {
	set := C.fd_set{}
	C.FD_SET(handle, &set)

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