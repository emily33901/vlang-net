module net

import time

fn split_address(addr string) ?(string, u16) {
	port := addr.all_after_last(':').u64()
	address := addr.all_before_last(':')

	if port < u16(-1) {
		return address, u16(port)
	} else {
		return err_port_out_of_range
	}
}

fn time_opt_helper(t ?time.Time) ?time.Time { return t }
