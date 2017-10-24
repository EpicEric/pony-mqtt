use "net"

primitive MQTTConnectionFactory
  """
  An interface to easily establish an MQTT client over a TCP connection.
  """
  fun tag apply(auth': TCPConnectionAuth, notify': MQTTConnectionNotify iso) =>
    let notify: MQTTConnectionNotify iso = consume notify'
    let host': String = notify.host
    let port': String = notify.port
    TCPConnection(auth', consume notify, host', port')