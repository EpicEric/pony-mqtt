primitive MQTTErrorConnectConnected
  fun string(): String =>
    "Cannot connect: Already connected"

primitive MQTTErrorConnectSocket
  fun string(): String =>
    "Cannot connect: No connection established"

primitive MQTTErrorDisconnectDisconnected
  fun string(): String =>
    "Cannot disconnect: Already disconnected"

primitive MQTTErrorSubscribeTopic
  fun string(): String =>
    "Cannot subscribe: Invalid topic"

primitive MQTTErrorSubscribeQoS
  fun string(): String =>
    "Cannot subscribe: Invalid QoS"

primitive MQTTErrorSubscribeConnected
  fun string(): String =>
    "Cannot subscribe: Not connected"

primitive MQTTErrorUnsubscribeTopic
  fun string(): String =>
    "Cannot unsubscribe: Invalid topic"

primitive MQTTErrorUnsubscribeConnected
  fun string(): String =>
    "Cannot unsubscribe: Not connected"

primitive MQTTErrorPublishTopic
  fun string(): String =>
    "Cannot publish: Invalid topic"

primitive MQTTErrorPublishConnected
  fun string(): String =>
    "Cannot publish: Not connected"

primitive MQTTErrorConnectFailedRetry
  fun string(): String =>
    "[CONNECT] Could not establish a connection; retrying"

primitive MQTTErrorConnectFailed
  fun string(): String =>
    "[CONNECT] Could not establish a connection"

primitive MQTTErrorSocketRetry
  fun string(): String =>
    "Connection closed by remote server; retrying"

primitive MQTTErrorSocket
  fun string(): String =>
    "Connection closed by remote server"

primitive MQTTErrorTLS
  fun string(): String =>
    "Invalid TLS configuration"

primitive MQTTErrorConnectProtocol
  fun string(): String =>
    "[CONNACK] Unnacceptable protocol version"

primitive MQTTErrorConnectProtocolRetry
  fun string(): String =>
    "[CONNACK] Unnacceptable protocol version; retrying"

primitive MQTTErrorConnectID
  fun string(): String =>
    "[CONNACK] Connection ID rejected"

primitive MQTTErrorConnectIDRetry
  fun string(): String =>
    "[CONNACK] Connection ID rejected; retrying"

primitive MQTTErrorConnectServer
  fun string(): String =>
    "[CONNACK] Server unavailable"

primitive MQTTErrorConnectServerRetry
  fun string(): String =>
    "[CONNACK] Server unavailable; retrying"

primitive MQTTErrorConnectAuthentication
  fun string(): String =>
    "[CONNACK] Bad user name or password"

primitive MQTTErrorConnectAuthorization
  fun string(): String =>
    "[CONNACK] Unauthorized client"

primitive MQTTErrorSubscribeFailure
  fun string(): String =>
    "[SUBACK] Could not subscribe to topic"

primitive MQTTErrorServerCode
  fun string(): String =>
    "Unexpected server control code; disconnecting"

primitive MQTTErrorUnknownCode
  fun string(): String =>
    "Unknown control code; disconnecting"

primitive MQTTErrorUnexpectedFormat
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
  | MQTTErrorTLS
  | MQTTErrorConnectProtocol
  | MQTTErrorConnectProtocolRetry
  | MQTTErrorConnectID
  | MQTTErrorConnectIDRetry
  | MQTTErrorConnectServer
  | MQTTErrorConnectServerRetry
  | MQTTErrorConnectAuthentication
  | MQTTErrorConnectAuthorization
  | MQTTErrorSubscribeFailure
  | MQTTErrorServerCode
  | MQTTErrorUnknownCode
  | MQTTErrorUnexpectedFormat)
