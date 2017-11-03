# actor MQTTConnection

An actor that handles the connection to the MQTT server in the background. When created, it establishes a TCP connection to the specified broker and exchanges messages according to the protocol version. Afterwards, it can be called by the user to execute actions such as publishing messages or subscribing to topics, and triggers events in a [notify class](//classes/interface-mqttconnectionnotify.md) when receiving a request from the server or when encountering an error.

It creates a [TCPConnectionNotify](//classes/class-mqttconnectionmanager.md) object of its own, to interface with a TCP connection only through it. It also creates [three](//classes/class-mqttpingtimer.md) [different](//classes/class-mqttresendtimer.md) [timers](/classes/class-mqttreconnecttimer.md) to organize its workflow. The user can also specify reconnection, making this class dispose of all current state and attempt to establish a new connection.

## Public fields

#### auth : TCPConnectionAuth

The connection authority used in the TCP backend. Usually, this value is a cast from `env.root`.

#### host : String

The host where the MQTT broker is located, such as `localhost`, `37.187.106.16`, or `test.mosquitto.org`.

#### port : String

The port for the MQTT service. By default, most brokers use port `1883`.

## Public methods/behaviours

#### create

```pony
new create(
  auth': TCPConnectionAuth,
  notify': MQTTConnectionNotify iso,
  host': String,
  port': String = "1883",
  keepalive': U16 = 15,
  version': MQTTVersion = MQTTv311,
  retry_connection': U64 = 0,
  will_packet': (MQTTPacket | None) = None,
  client_id': String = "",
  user': (String | None) = None,
  pass': (String | None) = None) =>
```

Creates a connection to the MQTT server, interfacing the TCP connection with a user-defined [MQTT notify class](//classes/interface-mqttconnectionnotify.md), by handling incoming and outgoing requests.

The arguments are:

* `auth'`: \(required\) The connection authority used in the TCP backend. Usually, this value is a cast from `env.root`.

* `notify'`: \(required\) The `MQTTConnectionNotify` implemented by the user which will receive messages and interact with the MQTT client.

* `host'`: \(required\) The host where the MQTT broker is located, such as `localhost`, `37.187.106.16`, or `test.mosquitto.org`.

* `port'`: The port for the MQTT service. By default, most brokers use port `1883`.

* `keepalive'`: Duration in seconds for the keepalive mechanism. Default is `15`. The minimum is 5 seconds.

* `version'`: The [version](//classes/type-mqttversion.md) of the communication protocol. By default, it uses the fourth release of the protocol, version 3.1.1.

* `retry_connection'`: When the connection is closed by the server or due to a client error, attempt to reconnect at the specified interval in seconds. A value of zero means no reattempt will be made. Default is `0`.

* `will_packet'`: MQTT allows the client to send a [will message](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Will_Flag) when the connection with the server is unexpectedly lost. If this field is not `None`, then the specified package will be sent unless the client gracefully disconnects with the `disconnect()` behaviour without providing the will parameter.

* `client_id'`: A string that will be used as the client ID to the broker for this session. By default, it will generate a random string with 8 hexadecimal characters.

* `user'`: A string with the username to authenticate to the broker. If `None` or empty, no authentication will be made. Default is `None`.

* `pass'`: A string with the password to authenticate to the broker. If `None` or empty, an empty password will be used if `user'` is not `None`. Default is `None`.

#### disconnect

```pony
be disconnect(send_will: Bool = false) =>
```

Sends a DISCONNECT request to the broker, and gracefully ends the connection, discarding any will packet. If `send_will` is `true`, a publish message with the will packet will be sent prior to disconnecting.

It may trigger the following error:

* `Cannot disconnect: Already disconnected`

#### subscribe

```pony
be subscribe(topic: String, qos: U8 = 0) =>
```

Sends a SUBSCRIBE request to the broker for the associated topic.

It may trigger one of the following errors:

* `Cannot subscribe: Invalid topic`

* `Cannot subscribe: Invalid QoS`

* `Cannot subscribe: Not connected`

#### unsubscribe

```pony
be unsubscribe(topic: String) =>
```

Sends an UNSUBSCRIBE request to the broker from the associated topic.

It may trigger one of the following errors:

* `Cannot unsubscribe: Invalid topic`

* `Cannot unsubscribe: Not connected`

#### publish

```pony
be publish(packet: MQTTPacket) =>
```

Sends a PUBLISH request for the provided [packet message](//classes/class-mqttpacket.md), along with desired topic, QoS, and retain flag.

It may trigger one of the following errors:

* `Cannot publish: Invalid topic`

* `Cannot publish: Not connected`

## Advanced code documentation

This next section contains advanced topics, detailing how the code works behind the scenes. Be warned!

#### Communication over TCP

Pony-MQTT uses a [\_MQTTConnectionManager](//classes/class-mqttconnectionmanager.md) class that implements a TCPConnectionNotify to handle events. It receives messages \(`connected`, `connect_failed`, `closed`, `received`\) by private methods with the same name, with arguments `TCPConnection` and `_MQTTConnectionManager` tags as verification.

In the case of `_received`, however, we must receive data which may be incomplete -- which can be verified by the Remaining Length field from MQTT control packets. Once the size has been fixed in this function through the use of an internal buffer, the data is sent to `_parse_packet`, handling different control options.

#### Reconnection

When the connection has been established, but is lost later, this actor can restart a TCPConnection if defined by the user \(i.e. if the `retry_connection'` parameter is greater than zero\). This varies from the type of disconnection:

* **Socket errors** \(i.e. network has crashed, server was shut down etc.\): The program simply creates a [reconnect timer](/classes/class-mqttreconnecttimer.md) \(more information in the next section\) that periodically calls `_new_conn()`, which simply kickstarts a new TCPConnection with the same parameters. This timer can only be started upon calling `closed()`, if `_is_connected` was `true`.
* **CONNACK errors** \(i.e. wrong connection parameters\): The program closes the connection from the client side, alters its parameters, and retries with `_new_conn()`. Here are the three different correctable errors and how the client attempts to fix them:
  1. _Unnacceptable protocol version_: Try with an older protocol version \(for example, 3.1 instead of 3.1.1\). If already at the oldest protocol version, drop connection.

  1. _Connection ID rejected_: Randomize the current client ID. This can lead to infinite loops on poorly configured brokers or clients.

  2. _Server unavailable_: Simply retry the connection. This can lead to infinite loops on poorly configured brokers or clients.

#### Timers

There are a total of three timers used in the MQTTConnection actor. Two of them, [\_MQTTPingTimer](//classes/class-mqttpingtimer.md) and [\_MQTTResendTimer](//classes/class-mqttresendtimer.md), handle message-passing once a connection has been established. The other one, [\_MQTTReconnectTimer](/classes/class-mqttreconnecttimer.md), is only called in cases listed in the section above, where a connection should be retried every few seconds.

#### Private methods

Two auxiliary private methods are used throughout the actor to aid in repetitive tasks. They are:

* `_random_string(length: USize = 8)`: Generates a random hexadecimal string of the specified length.
* `_remaining_length(length': USize)`: Generates an array of bytes in the [format specified by the MQTT protocol](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718023) for the "Remaining Length" field.



