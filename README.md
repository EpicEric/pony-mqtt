# Pony-MQTT

A notify-based Pony implementation of a MQTT client.

## Status

[![Build Status](https://travis-ci.org/epiceric/pony-mqtt.svg?branch=master)](https://travis-ci.org/epiceric/pony-mqtt)

Pony MQTT is currently under pre-alpha development. Revisions are greatly appreciated, since this library likely contains major programming errors and bugs.

### Pending features

* Documentation.
* MQTTv31 support.
* Topic validator unit tests.
* Identify potential bugs.
* Evaluate if any refactoring is necessary.

### Planned features

* Auto-retry connection on socket errors if `retry_connection` is set.
* Auto-retry connection with older protocol version upon receiving "invalid version" CONNACK error code.
* Notify tests.
* MQTTv5 support.

## Installation

* Install [pony-stable](https://github.com/ponylang/pony-stable)
* Update your `bundle.json`

```json
{ 
  "type": "github",
  "repo": "epiceric/pony-mqtt"
}
```

* `stable fetch` to fetch your dependencies
* `use "mqtt"` to include this package
* `stable env ponyc` to compile your application
