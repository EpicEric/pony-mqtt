# type MQTTError

There is a
[notify](//classes/interface-mqttconnectionnotify.md)
function,
`on_error(conn: MQTTConnection ref, err: MQTTError, info: String)`,
that receives one of the possible `Stringable`primitives of an MQTTError to
represent a raised error, and any additional information if applicable.
You may choose to handle or ignore them.

It may be one of the following:

Error | State | Automatic action | Information
--- | --- | --- | ---
MQTTErrorConnectConnected | Connecting after establishing an MQTT connection. | |
MQTTErrorConnectSocket | Connecting without a TCP connection. | |
MQTTErrorDisconnectDisconnected | Disconnecting wihout a TCP connection. | |
MQTTErrorSubscribeTopic | Subscribing with invalid topic. | No subscription sent. |
MQTTErrorSubscribeQoS | Subscribing with invalid QoS. | No subscription sent. |
MQTTErrorSubscribeConnected | Subscribing without a TCP connection. | |
MQTTErrorUnsubscribeTopic | Unsubscribing with invalid topic. | No unsubscription sent. |
MQTTErrorUnsubscribeConnected | Unsubscribing without a TCP connection. | |
MQTTErrorPublishTopic | Publishing with invalid topic. | No publish sent. |
MQTTErrorPublishConnected | Publishing without a TCP connection. | |
MQTTErrorConnectFailedRetry | Error when establishing TCP connection. | Attempt reconnection. |
MQTTErrorConnectFailed | Error when establishing TCP connection. | End execution. |
MQTTErrorSocketRetry | TCP connection closed by remote server. | Attempt reconnection. |
MQTTErrorSocket | TCP connection closed by remote server. | End execution. |
MQTTErrorTLSConfiguration | Failure when creating an SSL client. | End execution. |
MQTTErrorTLSAuthentication | Invalid SSL authentication credentials. | End execution. |
MQTTErrorConnectProtocol | Invalid [MQTT version](//classes/type-mqttversion.md). | End execution. |
MQTTErrorConnectProtocolRetry | Invalid [MQTT version](//classes/type-mqttversion.md). | Attempt reconnection with lower protocol version. |
MQTTErrorConnectID | Invalid client ID. | End execution. |
MQTTErrorConnectIDRetry | Invalid cliend ID. | Attempt reconnection with random ID. |
MQTTErrorConnectServer | MQTT server is unavailable. | End execution. |
MQTTErrorConnectServerRetry | MQTT server is unavailable. | Attempt reconnection. |
MQTTErrorConnectAuthentication | Invalid username or password. | End execution. |
MQTTErrorConnectAuthorization | Unauthorized client. | End execution. |
MQTTErrorSubscribeFailure | Subscription to topic was not accepted. | | The subscription topic.
MQTTErrorServerCode | A server control code (such as CONNECT or SUBSCRIBE) was sent to this client. | End connection. | The control code as text.
MQTTErrorUnknownCode | An unknown control code was received. | End connection. | The control code byte in hexadecimal.
MQTTErrorUnexpectedFormat | A generic error when parsing a packet fails mid-way. | End connection. |
