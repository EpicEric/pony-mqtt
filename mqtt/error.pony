primitive MQTTErrorConnectConnected
  """
  This error is triggered when a connection is attempted when already connected.
  """

  fun string(): String =>
    "Cannot connect: Already connected"

primitive MQTTErrorConnectSocket
  """
  This error is triggered when a connection is attempted without a previous TCP
  connection.
  """

  fun string(): String =>
    "Cannot connect: No connection established"

primitive MQTTErrorDisconnectDisconnected
  """
  This error is triggered when a disconnection is attempted without a previous
  TCP connection.
  """

  fun string(): String =>
    "Cannot disconnect: Already disconnected"

primitive MQTTErrorSubscribeTopic
  """
  This error is triggered when subscribing with an invalid topic filter.
  """

  fun string(): String =>
    "Cannot subscribe: Invalid topic"

primitive MQTTErrorSubscribeQoS
  """
  This error is triggered when subscribing with an invalid QoS value.
  """

  fun string(): String =>
    "Cannot subscribe: Invalid QoS"

primitive MQTTErrorSubscribeConnected
  """
  This error is triggered when subscribing without a previous TCP connection.
  """

  fun string(): String =>
    "Cannot subscribe: Not connected"

primitive MQTTErrorUnsubscribeTopic
  """
  This error is triggered when unsubscribing with an invalid topic filter.
  """

  fun string(): String =>
    "Cannot unsubscribe: Invalid topic"

primitive MQTTErrorUnsubscribeConnected
  """
  This error is triggered when unsubscribing without a previous TCP connection.
  """

  fun string(): String =>
    "Cannot unsubscribe: Not connected"

primitive MQTTErrorPublishTopic
  """
  This error is triggered when publishing with an invalid topic filter.
  """

  fun string(): String =>
    "Cannot publish: Invalid topic"

primitive MQTTErrorPublishConnected
  """
  This error is triggered when publishing without a previous TCP connection.
  """

  fun string(): String =>
    "Cannot publish: Not connected"

primitive MQTTErrorConnectFailedRetry
  """
  This error is triggered when there was a TCP connection error.

  The connection actor will automatically try to reconnect.
  """

  fun string(): String =>
    "[CONNECT] Could not establish a connection; retrying"

primitive MQTTErrorConnectFailed
  """
  This error is triggered when there was a TCP connection error.

  The connection actor will automatically end execution.
  """

  fun string(): String =>
    "[CONNECT] Could not establish a connection"

primitive MQTTErrorSocketRetry
  """
  This error is triggered when the TCP connection was closed by the remote
  server.

  The connection actor will automatically try to reconnect.
  """

  fun string(): String =>
    "Connection closed by remote server; retrying"

primitive MQTTErrorSocket
  """
  This error is triggered when the TCP connection was closed by the remote
  server.

  The connection actor will automatically end execution.
  """

  fun string(): String =>
    "Connection closed by remote server"

primitive MQTTErrorTLSConfiguration
  """
  This error is triggered when an SSL client could not be created due to bad
  configuration.

  The connection actor will automatically end execution.
  """

  fun string(): String =>
    "Invalid TLS configuration"

primitive MQTTErrorTLSAuthentication
  """
  This error is triggered when the SSL credentials for authentication are
  invalid.

  The connection actor will automatically end execution.
  """

  fun string(): String =>
    "TLS authentication error"

primitive MQTTErrorConnectProtocolRetry
  """
  This error is triggered when the broker does not accept the current protocol
  version.

  The connection actor will automatically downgrade to a lower protocol version
  and try to reconnect.
  """

  fun string(): String =>
    "[CONNACK] Unnacceptable protocol version; retrying"

primitive MQTTErrorConnectProtocol
  """
  This error is triggered when the broker does not accept the current protocol
  version.

  The connection actor will automatically end execution.
  """

  fun string(): String =>
    "[CONNACK] Unnacceptable protocol version"

primitive MQTTErrorConnectID
  """
  This error is triggered when the client ID is invalid.

  The connection actor will automatically end execution.
  """

  fun string(): String =>
    "[CONNACK] Connection ID rejected"

primitive MQTTErrorConnectServerRetry
  """
  This error is triggered when the MQTT server is currently unavailable.

  The connection actor will automatically try to reconnect.
  """

  fun string(): String =>
    "[CONNACK] Server unavailable; retrying"

primitive MQTTErrorConnectServer
  """
  This error is triggered when the MQTT server is currently unavailable.

  The connection actor will automatically end execution.
  """

  fun string(): String =>
    "[CONNACK] Server unavailable"

primitive MQTTErrorConnectAuthentication
  """
  This error is triggered when either the username or the password for the MQTT
  connection are invalid.

  The connection actor will automatically end execution.
  """

  fun string(): String =>
    "[CONNACK] Bad user name or password"

primitive MQTTErrorConnectAuthorization
  """
  This error is triggered when either the client is unauthorized by the broker.

  The connection actor will automatically end execution.
  """

  fun string(): String =>
    "[CONNACK] Unauthorized client"

primitive MQTTErrorSubscribeFailure
  """
  This error is triggered when the subscription to a certain topic filter is
  denied by the server.

  The additional info array will contain the failed subscription topic.
  """

  fun string(): String =>
    "[SUBACK] Could not subscribe to topic"

primitive MQTTErrorServerCode
  """
  This error is triggered when a server control code (such as CONNECT or
  SUBSCRIBE) is sent to the client.

  The connection actor will automatically end execution.

  The additional info array will contain the control code string bytes.
  """

  fun string(): String =>
    "Unexpected server control code; disconnecting"

primitive MQTTErrorUnknownCode
  """
  This error is triggered when an unknown control code is sent to the client.

  The connection actor will automatically end execution.

  The additional info array will contain the control code byte.
  """

  fun string(): String =>
    "Unknown control code; disconnecting"

primitive MQTTErrorUnexpectedFormat
  """
  This error is triggered when there is an error when parsing a packet.

  The connection actor will automatically end execution.

  The additional info array will contain the bytes of the failed parsed packet.
  """

  fun string(): String =>
    "Unexpected format when processing packet; disconnecting"

type MQTTError is
  ( MQTTErrorConnectConnected
  | MQTTErrorConnectSocket
  | MQTTErrorDisconnectDisconnected
  | MQTTErrorSubscribeTopic
  | MQTTErrorSubscribeQoS
  | MQTTErrorSubscribeConnected
  | MQTTErrorUnsubscribeTopic
  | MQTTErrorUnsubscribeConnected
  | MQTTErrorPublishTopic
  | MQTTErrorPublishConnected
  | MQTTErrorConnectFailedRetry
  | MQTTErrorConnectFailed
  | MQTTErrorSocketRetry
  | MQTTErrorSocket
  | MQTTErrorTLSConfiguration
  | MQTTErrorTLSAuthentication
  | MQTTErrorConnectProtocolRetry
  | MQTTErrorConnectProtocol
  | MQTTErrorConnectID
  | MQTTErrorConnectServerRetry
  | MQTTErrorConnectServer
  | MQTTErrorConnectAuthentication
  | MQTTErrorConnectAuthorization
  | MQTTErrorSubscribeFailure
  | MQTTErrorServerCode
  | MQTTErrorUnknownCode
  | MQTTErrorUnexpectedFormat)
  """
  A type for all the possible errors raised by the connection to the notify
  class. Depending on the type of error, the user may choose to handle or ignore
  them.
  """
