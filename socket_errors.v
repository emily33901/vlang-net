module net

// These are errors regarding the net.Socket2 api
const (
	socket_errors_base = 0
	err_new_socket_failed = error_with_code('net.new_socket failed to create socket', socket_errors_base+1)
	err_option_not_settable = error_with_code('net.Socket.set_option_x option not settable', socket_errors_base+2)
	err_option_wrong_type = error_with_code('net.Socket.set_option_x option wrong type', socket_errors_base+3)
	err_invalid_port = error_with_code('', socket_errors_base+4)
)

pub fn socket_error(potential_code int) ?int {
	$if windows {
		if potential_code < 0 {
			last_error := wsa_error(C.WSAGetLastError())
			return error_with_code('socket error: $last_error', last_error)
		}
	} 
	$else {
		println('WARN: WrapSocketError() not implemented for this platform')
	}

	return potential_code
}