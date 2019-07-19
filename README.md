# Pony-MQTT

A notify-based implementation of an MQTT client written in the [Pony language](https://www.ponylang.org/).

## Status

[![CircleCI](https://circleci.com/gh/EpicEric/pony-mqtt.svg?style=svg)](https://circleci.com/gh/EpicEric/pony-mqtt)

Pony-MQTT is in alpha, which means breaking changes are expected. Please read [CONTRIBUTING.md](CONTRIBUTING.md) if you wish to lend a hand.

### Available features

* Support for MQTT protocol versions 3.1 and 3.1.1 through TCP.
* TLS, authentication, and auto-retry connection.
* QoS for publish, subscribe, unsubscribe.

## Installation

* Install [pony-stable](https://github.com/ponylang/pony-stable).
* Add the following to your `bundle.json`:

```json
[
  ...,
  { 
    "type": "github",
    "repo": "epiceric/pony-mqtt"
  }
]
```

* `stable fetch` to fetch your dependencies.
* `use "mqtt"` to include this package.
* `stable env ponyc` to compile your application.

### Installation with [`net-ssl`](https://github.com/ponylang/net-ssl)

Follow the installations of the package, and add the following to your `bundle.json`:

```json
[
  ...,
  { 
    "type": "github",
    "repo": "epiceric/pony-mqtt"
  },
  { 
    "type": "github",
    "repo": "ponylang/net-ssl"
  }
]
```

See the [TLS example](examples/tls/main.pony) to configure your `MQTTConnection` appropriately.

## Usage

Please refer to the [official documentation](https://epiceric.github.io/pony-mqtt-docs/) hosted on GitHub Pages.
