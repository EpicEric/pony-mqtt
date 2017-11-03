# Errors

There is a [notify](//classes/interface-mqttconnectionnotify.md) function, `on_error(conn: MQTTConnection ref, message: String)`, that receives a string to represent a raised error. You may choose to handle or ignore them.

It may be one of the following:

* When calling disconnect\(\):

  * `Cannot disconnect: Already disconnected`

* When calling subscribe\(\):

  * `Cannot unsubscribe: Invalid topic`

  * `Cannot unsubscribe: Not connected`

* When calling unsubscribe\(\):

  * `Cannot unsubscribe: Invalid topic`

  * `Cannot unsubscribe: Not connected`

* When calling publish\(\):

  * `Cannot publish: Invalid topic`

  * `Cannot publish: Not connected`

---

* When connecting:

  * `[CONNECT] Could not establish a connection; retrying` \(if `retry_connection` is `true`\)

  * `[CONNECT] Could not establish a connection` \(if `retry_connection` is `false`\)

  * `Cannot connect: Already connected`

  * `Cannot connect: No connection established`

  * `Invalid topic for will packet; ignoring`

* On unexpected disconnect:

  * `Connection closed by remote server; reconnecting` \(if `retry_connection` is `true`\)

  * `Connection closed by remote server` \(if `retry_connection` is `false`\)

* When parsing packets:

  * `[CONNACK] Unnacceptable protocol version` \(retries if `retry_connection` is `true`\)

  * `[CONNACK] Connection ID rejected` \(retries if `retry_connection` is `true`\)

  * `[CONNACK] Server unavailable` \(retries if`retry_connection`is`true`\)

  * `[CONNACK] Bad user name or password`

  * `[CONNACK] Unauthorized client`

  * `[SUBACK] Could not subscribe to topic '<topic>'`

  * `[{CODE}] Unexpected control code; disconnecting`

  * `[0x{XX}] Unknown control code; disconnecting`

  * `Unexpected format when processing packet; disconnecting`



