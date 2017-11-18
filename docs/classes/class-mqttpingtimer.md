# class \_MQTTPingTimer

A timer to send PINGREQ messages to the server periodically. Currently, it
fires at 75% of the keepalive time \(i.e. if keepalive is set to 10 seconds,
it fires every 7.5 seconds\).
