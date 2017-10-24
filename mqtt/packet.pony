class val MQTTPacket
  let topic: String
  let message: Array[U8] val
  let qos: U8
  let id: U16

  new val create(topic': String, message': Array[U8] val, qos': U8 = 0, id': U16 = 0) =>
    topic = topic'
    message = message'
    qos = if qos' <= 2 then qos' else 0 end
    id = id'
