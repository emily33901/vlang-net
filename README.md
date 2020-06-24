# net
This module is intended to replace the net module in vlib - it is the Go sockets api we have all been waiting for. Its currently a work in progress but TCP is already up and running and UDP is in the works.

# Examples
```go
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
// Cast to string and print result
println(tos(result.data, result.len).clone())
```

You can find some more complex examples in [examples/](https://github.com/emily33901/vlang-net/tree/master/examples)

