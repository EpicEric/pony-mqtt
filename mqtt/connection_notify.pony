use "net"

class MQTTConnectionNotify is TCPConnectionNotify
  """
  A TCPConnectionNotify class that redirects all messages to an MQTTConnection actor.
  """
  let host: String
  let port: String
  let _connection: _MQTTConnection

  new iso create(
    client': MQTTClient iso,
    host': String = "localhost",
    port': String = "1883",
    keepalive': U16 = 15,
    version': MQTTVersion = MQTTv311,
    retry_connection': Bool = false, //TODO
    client_id': String = "",
    user': (String | None) = None,
    pass': (String | None) = None
  ) =>
    host = host'
    port = port'
    _connection = _MQTTConnection(consume client', host', port', keepalive', version',
      retry_connection', client_id', user', pass')

  fun ref connected(conn: TCPConnection ref) =>
    _connection.connected(conn)

  fun ref connect_failed(conn: TCPConnection ref) =>
     _connection.connect_failed(conn)

  fun ref closed(conn: TCPConnection ref) =>
    _connection.closed(conn)

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso,
    times: USize): Bool
  =>
    _connection.received(conn, consume data, times)
    false
