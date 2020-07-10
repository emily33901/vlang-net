module net

// These are errors regarding the net.Socket2 api
const (
	socket_errors_base = 0
	err_new_socket_failed = error_with_code('net: new_socket failed to create socket', socket_errors_base+1)
	err_option_not_settable = error_with_code('net: set_option_xxx option not settable', socket_errors_base+2)
	err_option_wrong_type = error_with_code('net: set_option_xxx option wrong type', socket_errors_base+3)
	err_invalid_port = error_with_code('', socket_errors_base+4)
	err_port_out_of_range = error_with_code('', socket_errors_base+5)
	err_no_udp_remote = error_with_code('', socket_errors_base+6)
	err_connect_failed = error_with_code('net: connect failed', socket_errors_base+7)
	err_connect_timed_out = error_with_code('net: connect timed out', socket_errors_base+8)
	err_read_timed_out = error_with_code('net: read timed out', socket_errors_base+9)
	err_read_timed_out_code = socket_errors_base+9
	err_write_timed_out = error_with_code('net: write timed out', socket_errors_base+10)
	err_write_timed_out_code = socket_errors_base+10
)

pub fn socket_error(potential_code int) ?int {
	$if windows {
		if potential_code < 0 {
			last_error := wsa_error(C.WSAGetLastError())
			return error_with_code('net: socket error: $last_error', last_error)
		}
	} 
	$else {
		if potential_code < 0 {
			last_error := error_code()
			return error_with_code('net: socket error: $last_error', last_error)
		}
	}

	return potential_code
}

pub fn wrap_error(error_code int) ? {
	$if windows {
		enum_error := wsa_error(error_code)
		return error_with_code('socket error: $enum_error', error_code)
	} 
	$else {
		return error_with_code('net: socket error: $error_code', error_code)
	}
}