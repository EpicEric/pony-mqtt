use "net"

interface val _SSLContext[A: Any iso]
  fun client(hostname: String): A^ ?

interface _SSLConnection[A: Any iso] is TCPConnectionNotify
  new iso create(notify: TCPConnectionNotify iso, ssl: A)
