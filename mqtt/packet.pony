class val MQTTPacket
  """
  An immutable, sendable packet, which can be published by the client or
  received from the server in PUBLISH messages, and if a Will is set upon
  connection.
  """

  let topic: String
  """
  The topic the packet is associated with. Be aware that user-defined topics
  may not follow the topic name rules of the protocol.
  """

  let message: Array[U8] val
  """
  The packet's payload.
  """

  let retain: Bool
  """
  The RETAIN flag in packets. If set to `true`, the server must retain the
  packet, sending it to late client subscriptions to the corresponding topic.
  """

  let qos: U8
  """
  The QoS of the packet, i.e. how the protocol guarantees dispatching. There are three possible values:

  * 0 \(at most once\): The packet is sent only one time, and may be lost.
  * 1 \(at least once\): The package is sent repeatedly until the receiver
  successfully acknowledges it.
  * 2 \(exactly once\): The packet will reach its destination thanks to an MQTT
  handshake, without loss or duplication.

  Invalid values will be automatically set to 0.
  """

  let id: U16
  """
  The packet identifier, used for control between the client and the server.
  It should not be set by the user when sending a packet, since the value will
  be overwritten before being sent to the broker.
  """

  new val create(
    topic': String,
    message': Array[U8] val,
    retain': Bool = false,
    qos': U8 = 0,
    id': U16 = 0)
  =>
    """
    Creates a packet.
    """
    topic = topic'
    message = message'
    retain = retain'
    qos = if qos' <= 2 then qos' else 0 end
    id = id'
