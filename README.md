# Pony-MQTT

A notify-based implementation of a MQTT client written in the [Pony language](https://www.ponylang.org/).

## Status

[![Build Status](https://travis-ci.org/EpicEric/pony-mqtt.svg?branch=master)](https://travis-ci.org/EpicEric/pony-mqtt)

Pony MQTT is in alpha version. Revisions are greatly appreciated, since this library likely contains major programming errors and bugs.

### Available features

* Support for MQTT versions 3.1 and 3.1.1 through TCP.
* Authentication and auto-retry connection.
* QoS for publish, subscribe, unsubscribe.

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

## Usage

Please refer to the [official documentation](https://epiceric.gitbooks.io/pony-mqtt/) hosted on GitBook.
