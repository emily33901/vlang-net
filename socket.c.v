module net 

struct C.in_addr {
mut:
	s_addr int
}

struct C.sockaddr {
}

struct C.sockaddr_in {
mut:
	sin_family int
	sin_port   int
	sin_addr   C.in_addr
}

struct C.addrinfo {
mut:
	ai_family    int
	ai_socktype  int
	ai_flags     int
	ai_protocol  int
	ai_addrlen   int
	ai_addr      voidptr
	ai_canonname voidptr
	ai_next      voidptr
}

struct C.sockaddr_storage {
}

fn C.socket() int

fn C.setsockopt() int

fn C.htonl() int

fn C.htons() int

fn C.bind() int

fn C.listen() int

fn C.accept() int

fn C.getaddrinfo() int

fn C.connect() int

fn C.send() int
fn C.sendto() int

fn C.recv() int
fn C.recvfrom() int

fn C.shutdown() int

fn C.ntohs() int

fn C.getsockname() int

// defined in builtin
// fn C.read() int
// fn C.close() int

fn C.ioctlsocket() int
fn C.fnctl() int

fn C.@select() int
fn C.FD_SET()
struct C.fd_set { 
pub:
	fd_count u32
}