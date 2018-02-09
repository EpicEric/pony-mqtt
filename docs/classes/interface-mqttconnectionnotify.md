# interface MQTTConnectionNotify

A user notify interface to create an event-based client class for your MQTT connections. It should implement the `on_connect()` and any others of the methods below.

## Public methods

#### on\_connect

```pony
fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
```

Triggered when a connection with the server is successful. Receives the [connection instance](//classes/actor-mqttconnection.md) and if [a session](https://www.hivemq.com/blog/mqtt-essentials-part-7-persistent-session-queuing-messages) is available in the broker.

This method **must** be implemented by your class.

#### on\_message

```pony
fun ref on_message(conn: MQTTConnection ref, packet: MQTTPacket) =>
```

Triggered when a message from the server is received. Receives the [connection instance](//classes/actor-mqttconnection.md), and the corresponding [message](//classes/class-mqttpacket.md).

#### on\_publish

```pony
fun ref on_publish(conn: MQTTConnection ref, packet: MQTTPacket) =>
```

Triggered when a packet sent from this client is successfully acknowledged by the server \(following the QoS specifications\). Receives the [connection instance](//classes/actor-mqttconnection.md), and the corresponding [message](//classes/class-mqttpacket.md).

#### on\_subscribe

```pony
fun ref on_subscribe(conn: MQTTConnection ref, topic: String, qos: U8) =>
```

Triggered when the server acknowledges a subscription to a topic. Receives the [connection instance](//classes/actor-mqttconnection.md), the corresponding topic and the associated QoS of the subscription.

#### on\_unsubscribe

```pony
fun ref on_unsubscribe(conn: MQTTConnection ref, topic: String) =>
```

Triggered when the server acknowledges a subscription to a topic. Receives the [connection instance](//classes/actor-mqttconnection.md), and the corresponding topic.

#### on\_ping

```pony
fun ref on_ping(conn: MQTTConnection ref) =>
```

Triggered when a ping request is replied to \(as part of the keepalive policy\). Receives the [connection instance](//classes/actor-mqttconnection.md).

#### on\_disconnect

```pony
fun ref on_disconnect(conn: MQTTConnection ref) =>
```

Triggered when the connection to the server is closed by the user. Receives the [connection instance](//classes/actor-mqttconnection.md).

When disconnected, packets and subscriptions should no longer be sent, and session data may be lost unless reconnection is set and `clean_session'` is `false`.

#### on\_error

```pony
fun ref on_error(conn: MQTTConnection ref, message: String) =>
```

Triggered when an error has occured. Receives the [connection instance](//classes/actor-mqttconnection.md).

Some errors may result in the connection to the server being closed afterwards. Errors include, but are not limited to:

* Invalid actions, such as connecting to an already connected server, or disconnecting/publishing/subscribing when the connection is closed.

* Unreachable host.

* Invalid topics when publishing a packet.

* Connection closed by the server.

* Incorrect connection settings.

* Unexpected package format from the server.

