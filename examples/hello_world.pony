use "../mqtt"


class MyClient is MQTTClient
  let _env: Env

  new create(env: Env) =>
    _env = env

  fun ref on_connect(conn: MQTTConnection ref) =>
    _env.out.print("[CONNACK] Connected.")
    conn.subscribe("pony/#")

  fun ref on_message(conn: MQTTConnection ref, packet: MQTTPacket val) =>
    _env.out.print(packet.topic + " -- " + String.from_array(packet.message))
    conn.disconnect()

  fun ref on_publish(conn: MQTTConnection ref, packet: MQTTPacket val) =>
    _env.out.print("[PUBLISH] Sent packet to topic '" + packet.topic + "'.")

  fun ref on_subscribe(conn: MQTTConnection ref, topic: String, qos: U8) =>
    _env.out.print("[SUBACK] Subscribed to topic '" + topic + "'.")
    conn.publish(MQTTPacket("pony/hello", ['w'; 'o'; 'r'; 'l'; 'd'], 0))

  fun ref on_unsubscribe(conn: MQTTConnection ref, topic: String) =>
    _env.out.print("[UNSUBACK] Unsubbed from topic '" + topic + "'.")

  fun ref on_ping(conn: MQTTConnection ref) =>
    _env.out.print("[PINGRESP] Success")

  fun ref on_disconnect(conn: MQTTConnection ref) =>
    _env.out.print("Connection successfully closed. Bye-bye!")

  fun ref on_error(conn: MQTTConnection ref, message: String) =>
    _env.out.print("[MQTT-Error] " + message)


actor Main
  new create(env: Env) =>
    try
      MQTTConnectionFactory(
        env.root as AmbientAuth,
        MQTTConnectionNotify(recover MyClient(env) end, "localhost", "1883", 15, MQTTv31)
      )
    end
