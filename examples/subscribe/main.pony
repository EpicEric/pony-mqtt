use "mqtt"

class iso MQTTSubNotify is MQTTConnectionNotify
  """
  Subscribe to the $SYS topic and print every message received.
  """

  let _env: Env

  new iso create(env: Env) =>
    _env = env

  fun ref on_connect(
    conn: MQTTConnectionInterface ref, session_present: Bool)
  =>
    """
    Subscribe to $SYS/# topic upon connecting.
    """
    _env.out.print("> Connected.")
    conn.subscribe("$SYS/#")

  fun ref on_message(conn: MQTTConnectionInterface ref, packet: MQTTPacket) =>
    """
    Print received messages.
    """
    _env.out.print(packet.topic + " -- " + String.from_array(packet.message))

  fun ref on_publish(conn: MQTTConnectionInterface ref, packet: MQTTPacket) =>
    None

  fun ref on_subscribe(
    conn: MQTTConnectionInterface ref, topic: String, qos: U8)
  =>
    """
    Confirm subscription.
    """
    _env.out.print("> Subscribed to topic '" + topic + "'.")

  fun ref on_unsubscribe(conn: MQTTConnectionInterface ref, topic: String) =>
    None

  fun ref on_ping(conn: MQTTConnectionInterface ref) =>
    None
  
  fun ref on_disconnect(conn: MQTTConnectionInterface ref) =>
    None

  fun ref on_error(
    conn: MQTTConnectionInterface ref, err: MQTTError, info: Array[U8] val)
  =>
    """
    Print error.
    """
    _env.out.print("MqttError: " + err.string())

actor Main
  new create(env: Env) =>
    try
      MQTTConnection(
        env.root as AmbientAuth,
        MQTTSubNotify(env),
        "localhost",
        "1883")
    end
