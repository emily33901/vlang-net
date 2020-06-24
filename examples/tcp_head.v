import emily33901.net
import time

// Make a new connection
mut conn := net.dial_tcp('google.com:80')?
// Simple http HEAD request for a file
conn.write('HEAD /index.html HTTP/1.0\r\n\r\n'.bytes())?
// Make sure to set a timeout so we can wait for a response!
conn.set_read_timeout(10 * time.second)
// Read all the data that is waiting
result := conn.read()?

println(tos(result.data, result.len).clone())