primitive MQTTv31
  """
  Third version of the MQTT protocol.
  """

primitive MQTTv311 is _MQTTVersionDowngradable
  """
  Fourth version of the MQTT protocol. It is also the default version.
  """

  fun downgrade(): MQTTVersion =>
    """
    If this version is unsupported by the broker, try the third version of
    the protocol.
    """
    MQTTv31

type MQTTVersion is (MQTTv31 | MQTTv311)
  """
  A type with all implemented versions of the MQTT protocol as primitives. It
  can be set by the user when creating a connection with MQTTConnection.

  Upon receiving an "invalid version" CONNACK error from the server with the
  `retry_connection` flag set, the connection will automatically try
  reconnection with an older version. If already at the oldest version
  (currently, MQTTv31), it will stop reconnection.
  """

trait val _MQTTVersionDowngradable
  """
  Private trait to determine that an MQTT version can be downgraded to a
  previous version of the protocol.
  """

  fun downgrade(): MQTTVersion
    """
    Returns the previous version of the MQTT protocol.
    """