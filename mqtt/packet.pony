class val MQTTPacket
  """
  A published message to/from the MQTT broker. Contains the publishing topic,
  the message, the designated QoS, if the message is retained and a connection-specific ID.
  """
  let topic: String
  let message: Array[U8] val
  let retain: Bool
  let qos: U8
  let id: U16

  new val create(topic': String, message': Array[U8] val, retain': Bool = false, qos': U8 = 0, id': U16 = 0) =>
    topic = topic'
    message = message'
    retain = retain'
    qos = if qos' <= 2 then qos' else 0 end
    id = id'
