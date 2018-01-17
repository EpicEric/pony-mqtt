# Getting started

Follow this guide to get started on using Pony-MQTT:

* Install
[pony-stable](https://github.com/ponylang/pony-stable).

* Update your `bundle.json`:

```json
{
  "type": "github",
  "repo": "epiceric/pony-mqtt"
}
```

* `stable fetch` to fetch your dependencies.

* Write an application with `use "mqtt"` that creates a [MQTTConnection](//classes/actor-mqttconnection.md) with a class implementing [MQTTConnectionNotify](//classes/interface-mqttconnectionnotify.md):

```pony
use "mqtt"

class iso MyNotify is MQTTConnectionNotify
  new iso create(...) =>
    // ...

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    // ...

actor Main
  new create(env: Env) =>
    try
      MQTTConnection(
        env.root as AmbientAuth,
        MyNotify(...),
        "localhost",
        "1883")
    end
```

* `stable env ponyc` to compile your application.
