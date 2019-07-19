use "net"

interface tag MQTTConnectionInterface
  be disconnect(send_will: Bool = false)
    """
    Sends a DISCONNECT request to the broker, and gracefully ends the MQTT and
    TCP connections.

    If send_will is true, the will packet will be sent before disconnecting.
    """
  
  be subscribe(topic: String, qos: U8 = 0)
    """
    Sends a SUBSCRIBE request to the broker for the associated topic filter,
    with the specified QoS level.
    """
  
  be unsubscribe(topic: String)
    """
    Sends an UNSUBSCRIBE request to the broker from the associated topic filter.
    """

  be publish(packet: MQTTPacket)
    """
    Sends a PUBLISH request for the provided packet message, along with desired
    topic, QoS, and retain flag.

    This behaviour will strip any package control ID.
    """

  be dispose()
    """
    Disposes of this connection.
    """

  fun local_address(): NetAddress ?
    """
    Returns the network address of this client. The result is the same of
    `TCPConnection.local_address()?`.
    """

  fun remote_address(): NetAddress ?
    """
    Returns the network address of the broker. The result is the same of
    `TCPConnection.remote_address()?`.
    """
