# Examples

These are a few simple examples to help you take a look at what you can do with Pony-MQTT.

## Hello world

Simply enough, this program connects to an MQTT broker, sends a message and disconnects.

```pony
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
```

## Subscribe

Connect to a broker and print every message on the `$SYS/#` topics.

```pony
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

  fun ref on_subscribe(conn: MQTTConnection ref, topic: String, qos: U8) =>
    """
    Confirm subscription.
    """
    _env.out.print("> Subscribed to topic '" + topic + "'.")

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

```
