use "net"

primitive MQTTConnectionConsumer
  """
  A helper function to easily establish MQTT clients over a TCP connection.
  """
  fun tag apply(notify': MQTTConnectionNotify iso) =>
    let notify: MQTTConnectionNotify iso = consume notify'
    let auth: TCPConnectionAuth = notify.auth
    let host: String = notify.host
    let port: String = notify.port
    TCPConnection(auth, consume notify, host, port)