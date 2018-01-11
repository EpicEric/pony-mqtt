# primitive MQTTUtils

Provides functions used throughout
[MQTTConnection](//classes/actor-mqttconnection.md)
that might be useful for users or tests.

## Public methods

#### random\_string

```pony
fun random_string(
  length: USize = 8,
  letters: String = "0123456789abcdef"): String val =>
```

Receives an integer and a string, and generates a random string of the
specified length with the provided characters.

#### remaining\_length

```pony
fun remaining_length(length: USize): Array[U8] val =>
```

Receives an integer, and generates an array of bytes in the
[format specified by the MQTT protocol](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718023)
for the "Remaining Length" field.
