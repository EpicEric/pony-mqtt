use "mqtt"

actor Main
  new create(env: Env) =>
    let id = "cpu506f6e79"
    let will = MQTTPacket(
      "homie/" + id + "/$online",
      "false".array(),
      true
    )
    try
      MQTTConnection(
        env.root as AmbientAuth,
        MQTTHomieDeviceNotify(env, id),
        "localhost",
        "1883"
        where client_id' = id,
        will_packet' = will,
        retry_connection' = true)
    end
