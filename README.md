# Pony-MQTT

A notify-based implementation of an MQTT client written in the [Pony language](https://www.ponylang.org/).

## Status

[![CircleCI](https://circleci.com/gh/EpicEric/pony-mqtt.svg?style=svg)](https://circleci.com/gh/EpicEric/pony-mqtt)

Pony-MQTT is in alpha, which means breaking changes are expected. Please read [CONTRIBUTING.md](CONTRIBUTING.md) if you wish to lend a hand.

### Available features

* Support for MQTT versions 3.1 and 3.1.1 through TCP.
* TLS, authentication, and auto-retry connection.
* QoS for publish, subscribe, unsubscribe.

## Installation

* Install [pony-stable](https://github.com/ponylang/pony-stable).
* Update your `bundle.json`:

```json
{ 
  "type": "github",
  "repo": "epiceric/pony-mqtt"
}
```

* `stable fetch` to fetch your dependencies.
* `use "mqtt"` to include this package.
* `stable env ponyc` to compile your application.

## Usage

Please refer to the [official documentation](https://epiceric.gitbooks.io/pony-mqtt/) hosted on GitBook.
