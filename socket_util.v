module net

const (
	socket_max_port = u16(-1)
)

pub fn validate_port(port int) ?u16 {
	if port <= socket_max_port {
		return u16(port)
	} else {
		return err_port_out_of_range
	}
}

fn split_address(addr string) ?(string, u16) {
	port := addr.all_after_last(':').int()
	address := addr.all_before_last(':')

	p := validate_port(port)?
	return address, p
}


