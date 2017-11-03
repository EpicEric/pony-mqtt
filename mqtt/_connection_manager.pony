use "net"

class _MQTTConnectionManager is TCPConnectionNotify
  """
  A TCPConnectionNotify class that manages and redirects all messages
  to an MQTTConnection actor.
  """
  let _connection: MQTTConnection

  new iso create(connection: MQTTConnection) =>
    _connection = connection

  fun ref connected(conn: TCPConnection ref) =>
    _connection._connected(conn, this)

  fun ref connect_failed(conn: TCPConnection ref) =>
     _connection._connect_failed(conn, this)

  fun ref closed(conn: TCPConnection ref) =>
    _connection._closed(conn, this)

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso,
    times: USize): Bool =>
    _connection._received(conn, this, consume data)
    false
