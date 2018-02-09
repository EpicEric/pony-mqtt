# type MQTTVersion

A type with all implemented versions of the MQTT protocol as primitives. It can be set by the user when [creating a connection](//classes/actor-mqttconnection.md). Current values:

* `primitive MQTTv31`: Third version of the protocol.

* `primitive MQTTv311`: \(default\) Fourth version of the protocol.

Upon receiving an "invalid version" CONNACK error from the server with the `retry_connection` flag set, the connection will automatically try reconnection with an older version. If already at the oldest version (currently `MQTTv31`), it will stop reconnection.
