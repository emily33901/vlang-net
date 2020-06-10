module net

#include <sys/socket.h>
#include <unistd.h>
#include <netinet/in.h>
#include <netdb.h>
#include <errno.h>
fn error_code() int {
	return C.errno
}

fn init() {
}

pub const (
	msg_nosignal = 0x4000
)

const (
	so_accept_conn = C.SO_ACCEPT_CONN
)

#flag solaris -lsocket
