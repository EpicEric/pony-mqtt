use "mqtt"

class iso MQTTSubNotify is MQTTConnectionNotify
  """
  Subscribe to the $SYS topic and print every message received.
  """
  let _env: Env

  new iso create(env: Env) =>
    _env = env

  fun ref on_connect(conn: MQTTConnection ref) =>
    """
    Subscribe to $SYS/# topic upon connecting.
    """
    _env.out.print("> Connected.")
    conn.subscribe("$SYS/#")

  fun ref on_message(conn: MQTTConnection ref, packet: MQTTPacket) =>
    """
    Print received messages.
    """
    _env.out.print(packet.topic + " -- " + String.from_array(packet.message))

  fun ref on_publish(conn: MQTTConnection ref, packet: MQTTPacket) =>
    None

  fun ref on_subscribe(conn: MQTTConnection ref, topic: String, qos: U8) =>
    """
    Confirm subscription.
    """
    _env.out.print("> Subscribed to topic '" + topic + "'.")

  fun ref on_unsubscribe(conn: MQTTConnection ref, topic: String) =>
    None

  fun ref on_ping(conn: MQTTConnection ref) =>
    None
  
  fun ref on_disconnect(conn: MQTTConnection ref) =>
    None

  fun ref on_error(conn: MQTTConnection ref, message: String) =>
    """
    Print error.
    """
    _env.out.print("MqttError: " + message)

actor Main
  new create(env: Env) =>
    try
      MQTTConnection(
        env.root as AmbientAuth,
        MQTTSubNotify(env),
        "localhost",
        "1883")
    end
