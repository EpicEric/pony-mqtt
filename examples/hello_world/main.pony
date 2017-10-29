use "mqtt"

class iso MQTTHelloWorldNotify is MQTTConnectionNotify
  """
  Sends a message and disconnects.
  """
  fun ref on_connect(conn: MQTTConnection ref) =>
    conn.publish(MQTTPacket("pony", "Hello, world!".array()))
    conn.disconnect()

actor Main
  new create(env: Env) =>
    try
      MQTTConnection(
        env.root as AmbientAuth,
        MQTTHelloWorldNotify,
        "localhost",
        "1883")
    end
