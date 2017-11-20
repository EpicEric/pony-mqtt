primitive MQTTErrorConnectConnected
  fun string(): String iso^ =>
    recover
      "Cannot connect: Already connected".clone()
    end

primitive MQTTErrorConnectSocket
  fun string(): String iso^ =>
    recover
      "Cannot connect: No connection established".clone()
    end

primitive MQTTErrorDisconnectDisconnected
  fun string(): String iso^ =>
    recover
      "Cannot disconnect: Already disconnected".clone()
    end

primitive MQTTErrorSubscribeTopic
  fun string(): String iso^ =>
    recover
      "Cannot subscribe: Invalid topic".clone()
    end

primitive MQTTErrorSubscribeQoS
  fun string(): String iso^ =>
    recover
      "Cannot subscribe: Invalid QoS".clone()
    end

primitive MQTTErrorSubscribeConnected
  fun string(): String iso^ =>
    recover
      "Cannot subscribe: Not connected".clone()
    end

primitive MQTTErrorUnsubscribeTopic
  fun string(): String iso^ =>
    recover
      "Cannot unsubscribe: Invalid topic".clone()
    end

primitive MQTTErrorUnsubscribeConnected
  fun string(): String iso^ =>
    recover
      "Cannot unsubscribe: Not connected".clone()
    end

primitive MQTTErrorPublishTopic
  fun string(): String iso^ =>
    recover
      "Cannot publish: Invalid topic".clone()
    end

primitive MQTTErrorPublishConnected
  fun string(): String iso^ =>
    recover
      "Cannot publish: Not connected".clone()
    end

primitive MQTTErrorConnectFailedRetry
  fun string(): String iso^ =>
    recover
      "[CONNECT] Could not establish a connection; retrying".clone()
    end

primitive MQTTErrorConnectFailed
  fun string(): String iso^ =>
    recover
      "[CONNECT] Could not establish a connection".clone()
    end

primitive MQTTErrorSocketRetry
  fun string(): String iso^ =>
    recover
      "Connection closed by remote server; retrying".clone()
    end

primitive MQTTErrorSocket
  fun string(): String iso^ =>
    recover
      "Connection closed by remote server".clone()
    end

primitive MQTTErrorConnectProtocol
  fun string(): String iso^ =>
    recover
      "[CONNACK] Unnacceptable protocol version".clone()
    end

primitive MQTTErrorConnectProtocolRetry
  fun string(): String iso^ =>
    recover
      "[CONNACK] Unnacceptable protocol version; retrying".clone()
    end

primitive MQTTErrorConnectID
  fun string(): String iso^ =>
    recover
      "[CONNACK] Connection ID rejected".clone()
    end

primitive MQTTErrorConnectIDRetry
  fun string(): String iso^ =>
    recover
      "[CONNACK] Connection ID rejected; retrying".clone()
    end

primitive MQTTErrorConnectServer
  fun string(): String iso^ =>
    recover
      "[CONNACK] Server unavailable".clone()
    end

primitive MQTTErrorConnectServerRetry
  fun string(): String iso^ =>
    recover
      "[CONNACK] Server unavailable; retrying".clone()
    end

primitive MQTTErrorConnectAuthentication
  fun string(): String iso^ =>
    recover
      "[CONNACK] Bad user name or password".clone()
    end

primitive MQTTErrorConnectAuthorization
  fun string(): String iso^ =>
    recover
      "[CONNACK] Unauthorized client".clone()
    end

primitive MQTTErrorSubscribeFailure
  fun string(): String iso^ =>
    recover
      "[SUBACK] Could not subscribe to topic".clone()
    end

primitive MQTTErrorServerCode
  fun string(): String iso^ =>
    recover
      "Unexpected server control code; disconnecting".clone()
    end

primitive MQTTErrorUnknownCode
  fun string(): String iso^ =>
    recover
      "Unknown control code; disconnecting".clone()
    end

primitive MQTTErrorUnexpectedFormat
  fun string(): String iso^ =>
    recover
      "Unexpected format when processing packet; disconnecting".clone()
    end

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
  | MQTTErrorUnexpectedFormat
  )
