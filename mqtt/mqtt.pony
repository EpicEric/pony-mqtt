"""
# Pony-MQTT

Pony-MQTT is a library implementing an MQTT client. It allows you to connect to
an MQTT broker and exchange messages through TCP. It complies with the MQTT 3.1
and 3.1.1 protocols.

## Usage

Follow this guide to get started on using Pony-MQTT:

* Install [pony-stable](https://github.com/ponylang/pony-stable).

* Update your `bundle.json`:

```json
{
  "type": "github",
  "repo": "epiceric/pony-mqtt"
}
```

* `stable fetch` to fetch your dependencies.

* Write an application with `use "mqtt"` that creates an MQTTConnection actor
with a class implementing the MQTTConnectionNotify interface:

```pony
use "mqtt"

class iso MyNotify is MQTTConnectionNotify
  new iso create(...) =>
    // ...

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    // ...

actor Main
  new create(env: Env) =>
    try
      MQTTConnection(
        env.root as AmbientAuth,
        MyNotify(...),
        "localhost",
        "1883")
    end
```

* `stable env ponyc` to compile your application.

## Examples

These are a few simple examples to help you take a look at what you can do with
Pony-MQTT.

### Hello world

Simple enough, this program connects to an MQTT broker, sends a message and
disconnects.

```pony
use "mqtt"

class iso MQTTHelloWorldNotify is MQTTConnectionNotify
  // Connects to the broker, sends a message and disconnects.
  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
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

### Subscribe

Connect to a broker and print every message on the `$SYS/#` topics.

```pony
use "mqtt"

class iso MQTTSubNotify is MQTTConnectionNotify
  // Subscribe to the $SYS topic and print every message received.
  let _env: Env

  new iso create(env: Env) =>
    _env = env

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    // Subscribe to $SYS/# topic upon connecting.
    _env.out.print("> Connected.")
    conn.subscribe("$SYS/#")

  fun ref on_message(conn: MQTTConnection ref, packet: MQTTPacket) =>
    // Print received messages.
    _env.out.print(packet.topic + " -- " + String.from_array(packet.message))

  fun ref on_subscribe(conn: MQTTConnection ref, topic: String, qos: U8) =>
    // Confirm subscription.
    _env.out.print("> Subscribed to topic '" + topic + "'.")

  fun ref on_error(
    conn: MQTTConnection ref, err: MQTTError, info: Array[U8] val)
  =>
    // Print error.
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
```
"""