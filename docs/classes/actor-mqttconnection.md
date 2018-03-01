# actor MQTTConnection

An actor that handles the connection to the MQTT server in the background. When created, it establishes a TCP connection to the specified broker and exchanges messages according to the protocol version. Afterwards, it can be called by the user to execute actions such as publishing messages or subscribing to topics, and triggers events in a [notify class](//classes/interface-mqttconnectionnotify.md) when receiving a request from the server or when encountering an error.

It creates a [TCPConnectionNotify](//classes/class-mqttconnectionhandler.md) object of its own, to interface with a TCP connection only through it. It also creates [three](//classes/class-mqttpingtimer.md) [different](//classes/class-mqttresendtimer.md) [timers](/classes/class-mqttreconnecttimer.md) to organize its workflow. The user can also specify reconnection, making this class dispose of all current state and attempt to establish a new connection.

It may raise one of many errors during execution; for more information, please refer to [MQTTError](//classes/type-mqtterror.md).

## Public fields

#### auth : TCPConnectionAuth

The connection authority used in the TCP backend. Usually, this value is a cast from `env.root`.

#### host : String

The host where the MQTT broker is located, such as `localhost`, `37.187.106.16`, or `test.mosquitto.org`.

#### port : String

The port for the MQTT service. By default, most brokers use port `1883`.

## Public methods

#### create

```pony
new create(
  auth': AmbientAuth,
  notify': MQTTConnectionNotify iso,
  host': String,
  port': String = "1883",
  keepalive': U16 = 15,
  version': MQTTVersion = MQTTv311,
  retry_connection': U64 = 0,
  clean_session': Bool = true,
  sslctx': (SSLContext | None) = None,
  sslhost': String = "",
  will_packet': (MQTTPacket | None) = None,
  client_id': String = "",
  user': (String | None) = None,
  pass': (String | None) = None)
=>
```

Creates a connection to the MQTT server, interfacing the TCP connection with a user-defined [MQTT notify class](//classes/interface-mqttconnectionnotify.md), by handling incoming and outgoing requests.

The arguments are:

* `auth'`: \(required\) The connection authority used in the TCP backend. Usually, this value is a cast from `env.root`.

* `notify'`: \(required\) The `MQTTConnectionNotify` implemented by the user which will receive messages and interact with the MQTT client.

* `host'`: \(required\) The host where the MQTT broker is located, such as `localhost`, `37.187.106.16`, or `test.mosquitto.org`.

* `port'`: The port for the MQTT service. By default, most brokers use port `1883`.

* `keepalive'`: Duration in seconds for the keepalive mechanism. If set to `0`, the keepalive mechanism is disabled, but ping messages will still be sent once in a while to avoid inactivity. Default is `15`.

* `version'`: The [version](//classes/type-mqttversion.md) of the communication protocol. By default, it uses the fourth release of the protocol, version 3.1.1.

* `retry_connection'`: When the connection is closed by the server or due to a client error, attempt to reconnect at the specified interval in seconds. A value of zero means no attempt to reconnect will be made. Default is `0`.

* `clean_session'`: Controls whether the broker should not store [a persistent session](https://www.hivemq.com/blog/mqtt-essentials-part-7-persistent-session-queuing-messages) for this connection. Sessions for a same client are identified by the `client_id'` parameter. Default is `true`.

* `sslctx'`: An SSLContext object, with client and certificate authority set appropriately, used when connecting to a TLS port in a broker. A value of `None` means no security will be implemented over the socket. Default is `None`.

* `sslhost'`: A String representing a host for signed certificates. If the hostname isn't part of the certificate, leave it blank. Default is `""`.

* `will_packet'`: MQTT allows the client to send a [will message](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Will_Flag) when the connection with the server is unexpectedly lost. If this field is an [MQTTPacket](//classes/class-mqttpacket.md) with a valid topic, then the specified package will be sent unless the client gracefully disconnects with the `disconnect()` behaviour without providing the will parameter.

* `client_id'`: A string that will be used as the client ID to the broker for this session. By default, it will generate a random string with 8 hexadecimal characters.

* `user'`: A string with the username to authenticate to the broker. If `None` or empty, no authentication will be made. Default is `None`.

* `pass'`: A string with the password to authenticate to the broker. If `None` or empty, an empty password will be used if `user'` is not `None`. Default is `None`.

#### disconnect

```pony
be disconnect(send_will: Bool = false) =>
```

Sends a DISCONNECT request to the broker, and gracefully ends the connection, discarding any will packet. If `send_will` is `true`, a publish message with the will packet will be sent prior to disconnecting.

#### subscribe

```pony
be subscribe(topic: String, qos: U8 = 0) =>
```

Sends a SUBSCRIBE request to the broker for the associated topic.

#### unsubscribe

```pony
be unsubscribe(topic: String) =>
```

Sends an UNSUBSCRIBE request to the broker from the associated topic.

#### publish

```pony
be publish(packet: MQTTPacket) =>
```

Sends a PUBLISH request for the provided [packet message](//classes/class-mqttpacket.md), along with desired topic, QoS, and retain flag.

#### local_address

```pony
fun local_address(): NetAddress ? =>
```

Returns the network address of this client. The result is the same of `TCPConnection.local_address()?`.

#### remote_address

```pony
fun remote_address(): NetAddress ? =>
```

Returns the network address of the broker. The result is the same of `TCPConnection.remote_address()?`.

## Advanced code documentation

This next section contains advanced topics, detailing how the code works behind the scenes. Be warned!

#### Communication over TCP

Pony-MQTT uses a [\_MQTTConnectionHandler](//classes/class-mqttconnectionhandler.md) class that implements a TCPConnectionNotify to handle events. It receives messages \(`connected`, `connect_failed`, `closed`, `received`\) by private methods with the same name, with arguments `TCPConnection` and `_MQTTConnectionHandler` tags as verification.

In the case of `_received`, however, we must receive data which may be incomplete -- which can be verified by the Remaining Length field from MQTT control packets. Once the size has been fixed in this function through the use of an internal buffer, the data is sent to `_parse_packet`, handling different control options.

#### Reconnection

When the connection has been established, but is lost later, this actor can restart a TCPConnection if defined by the user \(i.e. if the `retry_connection'` parameter is greater than zero\). This varies from the type of disconnection:

* **Socket errors** \(i.e. network has crashed, server was shut down etc.\): The program simply creates a [reconnect timer](/classes/class-mqttreconnecttimer.md) \(more information in the next section\) that periodically calls `_new_connection()`, which simply kickstarts a new TCPConnection with the same parameters. This timer can only be started upon calling `closed()`, if `_is_connected` was `true`.

* **CONNACK errors** \(i.e. wrong connection parameters\): The program closes the connection from the client side, alters its parameters, and retries with `_new_connection()`. Here are the three different correctable errors and how the client attempts to fix them:

  1. _Unnacceptable protocol version_: Try with an older protocol version \(for example, 3.1 instead of 3.1.1\). If already at the oldest protocol version, drop connection.

  2. _Connection ID rejected_: Randomize the current client ID. This can lead to infinite loops on poorly configured brokers or clients.

  3. _Server unavailable_: Simply retry the connection. This can lead to infinite loops on poorly configured brokers or clients.

#### Timers

There are a total of three timers used in the MQTTConnection actor. Two of them, [\_MQTTPingTimer](//classes/class-mqttpingtimer.md) and [\_MQTTResendTimer](//classes/class-mqttresendtimer.md), handle message passing once a connection has been established. The other one, [\_MQTTReconnectTimer](/classes/class-mqttreconnecttimer.md), is only called in cases listed in the section above, where a connection should be retried every few seconds.
