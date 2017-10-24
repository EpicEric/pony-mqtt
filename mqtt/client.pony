interface MQTTClient
  fun ref on_connect(conn: MQTTConnection ref) => None
  fun ref on_message(conn: MQTTConnection ref, packet: MQTTPacket val) => None
  fun ref on_publish(conn: MQTTConnection ref, packet: MQTTPacket val) => None
  fun ref on_subscribe(conn: MQTTConnection ref, topic: String) => None
  fun ref on_unsubscribe(conn: MQTTConnection ref, topic: String) => None
  fun ref on_ping(conn: MQTTConnection ref) => None
  fun ref on_disconnect(conn: MQTTConnection ref) => None
  fun ref on_error(conn: MQTTConnection ref, message: String) => None
