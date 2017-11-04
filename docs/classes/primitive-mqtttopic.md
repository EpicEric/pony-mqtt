# primitive MQTTTopic

Provides functions to verify if a topic is valid for publishing or subscribing.

## Public methods

#### validate\_publish

```pony
fun tag validate_publish(topic: String): Bool =>
```

Receives a string and verifies if it has no wildcard or null characters. Returns `true` if the topic is valid and `false` otherwise.

#### validate\_subscribe

```pony
fun tag validate_subscribe(topic: String): Bool =>
```

Receives a string and verifies if it has no null characters and the wildcard characters are properly segmented. Returns `true` if the topic is valid and `false` otherwise.
