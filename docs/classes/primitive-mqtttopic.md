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

#### match\_topic

```pony
fun tag match_topic(name: String, filter: String): Bool =>
```

Receives two strings: one representing a topic name for PUBLISH messages, and another representing a topic filter for SUBSCRIBE/UNSUBSCRIBE messages. Returns `true` if both the topic name and topic filter are valid, and the former matches the latter; and `false` otherwise.
