use "net"

primitive MQTTConnectionFactory
  fun tag apply(auth': TCPConnectionAuth, notify': MQTTConnectionNotify iso) =>
    let notify: MQTTConnectionNotify iso = consume notify'
    let host': String = notify.host
    let port': String = notify.port
    TCPConnection(auth', consume notify, host', port')