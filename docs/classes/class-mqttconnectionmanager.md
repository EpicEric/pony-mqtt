# class \_MQTTConnectionManager

A TCPConnectionNotify class that redirects all TCPConnection messages to its [MQTTConnection](//classes/actor-mqttconnection.md).

To confirm that only messages from the appropriate TCPConnection to an MQTT broker are allowed, and not from a different TCPConnection, all message redirection to the MQTTConnection requires an `_MQTTConnectionManager tag` representing this object.
