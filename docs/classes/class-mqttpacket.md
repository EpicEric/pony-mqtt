# class val MQTTPacket

An immutable, sendable packet, which can be published by the client or received from the server in PUBLISH messages and if a Will is set upon connection.

## Public fields

#### topic : String

A string of the topic the packet is associated with. User-defined topics may not follow the topic name rules of the protocol.

#### message : Array\[U8\] val

An array of bytes representing a packet's payload.

#### retain : Bool

A boolean value representing the RETAIN flag in packets. If set to `true`, the server must retain the packet, sending it to late client subscriptions to the corresponding topic.

#### qos : U8

An integer representing the QoS of the packet, i.e. how the protocol guarantees dispatching. There are three possible values:

* 0 \(at most once\): The packet is sent only one time, and may be lost.

* 1 \(at least once\): The package is sent repeatedly until the receiver successfully acknowledges it.

* 2 \(exactly once\): The packet will reach its destination thanks to an MQTT handshake, without loss or duplication.

Invalid values will be automatically set to 0.

#### id : U16

A packet identifier, used for control between the client and the server. It should not be used by the user, since the value will be overwritten.

## Public methods

#### create

```pony
new val create(
  topic': String,
  message': Array[U8] val,
  retain': Bool = false,
  qos': U8 = 0,
  id': U16 = 0) =>
```

Creates a packet.
