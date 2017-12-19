interface MQTTConnectionNotify
  """
  A notify interface to create an event-based client class
  for your MQTT connections.
  """

  fun ref on_connect(conn: MQTTConnection ref)
    """
    Called after successfully connecting to an MQTT broker.

    This method must be implemented.
    """

  fun ref on_message(conn: MQTTConnection ref, packet: MQTTPacket) =>
    """
    Called upon receiving a PUBLISH message from the broker.
    Receives said message.
    """
    None

  fun ref on_publish(conn: MQTTConnection ref, packet: MQTTPacket) =>
    """
    Called after succesfully publishing a message to the broker.
    Receives said message.
    """
    None

  fun ref on_subscribe(conn: MQTTConnection ref, topic: String, qos: U8) =>
    """
    Called after successfully subscribing to a topic.
    Receives said topic and the granted QoS.
    """
    None

  fun ref on_unsubscribe(conn: MQTTConnection ref, topic: String) =>
    """
    Called after successfully unsubscribing from a topic.
    Receives said topic.
    """
    None

  fun ref on_ping(conn: MQTTConnection ref) =>
    """
    Called after a ping to the server.
    """
    None

  fun ref on_disconnect(conn: MQTTConnection ref) =>
    """
    Called after disconnecting from the broker.
    """
    None

  fun ref on_error(
    conn: MQTTConnection ref, err: MQTTError, info: String = "")
  =>
    """
    Called when an error occurs. Receives the error message.
    """
    None
