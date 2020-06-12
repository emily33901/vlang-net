module net

// These are errors regarding the net.Socket2 api
const (
	socket_errors_base = 0
	err_new_socket_failed = error_with_code('net.new_socket failed to create socket', socket_errors_base+1)
	err_option_not_settable = error_with_code('net.Socket.set_option_xxx option not settable', socket_errors_base+2)
	err_option_wrong_type = error_with_code('net.Socket.set_option_xxx option wrong type', socket_errors_base+3)
	err_invalid_port = error_with_code('', socket_errors_base+4)
	err_port_out_of_range = error_with_code('', socket_errors_base+5)
	err_no_udp_remote = error_with_code('', socket_errors_base+6)
)

pub fn socket_error(potential_code int) ?int {
	$if windows {
		if potential_code < 0 {
			last_error := wsa_error(C.WSAGetLastError())
			return error_with_code('socket error: $last_error (from $potential_code)', last_error)
		}
	} 
	$else {
		println('WARN: socket_error() not implemented for this platform')
	}

	return potential_code
}