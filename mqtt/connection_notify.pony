interface MQTTConnectionNotify
  """
  A notify interface to create an event-based client class
  for your MQTT connections. At the very least, it must implement the 
  `on_connect()` method.
  """

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool)
    """
    Called after successfully connecting to an MQTT broker. Receives the
    connection and if [a session](https://www.hivemq.com/blog/mqtt-essentials-part-7-persistent-session-queuing-messages)
    is available in the broker.

    This method must be implemented.
    """

  fun ref on_message(conn: MQTTConnection ref, packet: MQTTPacket) =>
    """
    Called upon receiving a PUBLISH message from the broker. Receives the
    connection and said message.
    """
    None

  fun ref on_publish(conn: MQTTConnection ref, packet: MQTTPacket) =>
    """
    Called after succesfully publishing a message to the broker. Receives the
    connection and said message.
    """
    None

  fun ref on_subscribe(conn: MQTTConnection ref, topic: String, qos: U8) =>
    """
    Called after successfully subscribing to a topic. Receives the connection,
    said topic, and the associated QoS level of the subscription (from 0 to 2).
    """
    None

  fun ref on_unsubscribe(conn: MQTTConnection ref, topic: String) =>
    """
    Called after successfully unsubscribing from a topic. Receives the
    connection and said topic.
    """
    None

  fun ref on_ping(conn: MQTTConnection ref) =>
    """
    Called after a ping request is replied by the server. Receives the
    connection.
    """
    None

  fun ref on_disconnect(conn: MQTTConnection ref) =>
    """
    Called after the connection to the broker is closed by the user. Receives
    the connection. When disconnected, packets and subscriptions should no
    longer be sent, and session data may be lost unless reconnection is set
    and `clean_session'` is `false`.
    """
    None

  fun ref on_error(
    conn: MQTTConnection ref,
    err: MQTTError,
    info: Array[U8] val = recover val Array[U8] end)
  =>
    """
    Called when an error occurs. Receives the connection, the error code, and
    any additional byte array info if applicable.
    
    Some errors may result in the connection to the server being closed
    afterwards.
    """
    None
