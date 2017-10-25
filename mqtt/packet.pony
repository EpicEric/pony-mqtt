class val MQTTPacket
  """
  A published message to/from the MQTT broker. Contains the publishing topic,
  the message, the designated QoS and a connection-specific ID.
  """
  let topic: String
  let message: Array[U8] val
  let qos: U8
  let retain: Bool
  let id: U16

  new val create(topic': String, message': Array[U8] val, qos': U8 = 0, retain': Bool = false, id': U16 = 0) =>
    topic = if MQTTTopic.validate_publish(topic') then topic' else "$error/topic" end
    message = message'
    qos = if qos' <= 2 then qos' else 0 end
    retain = retain'
    id = id'
