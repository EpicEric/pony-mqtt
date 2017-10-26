use "net"

class MQTTConnectionManager is TCPConnectionNotify
  """
  A TCPConnectionNotify class that manages and redirects all messages to an MQTTConnection actor.
  """
  let _connection: MQTTConnection

  new iso create(connection: MQTTConnection) =>
    _connection = connection

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
