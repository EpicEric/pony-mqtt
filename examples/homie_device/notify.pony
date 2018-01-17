use "mqtt"
use "time"

class iso MQTTHomieDeviceNotify is MQTTConnectionNotify
  """
  A notifier for our device.
  """

  let _env: Env
  let _id: String
  var _device: (HomieDevice | None) = None

  new iso create(env: Env, id: String) =>
    _env = env
    _id = id

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _env.out.print(
      "[" +
      get_date() +
      "] Connected.")
    try
        (_device as HomieDevice).restart()
    else
      _device = HomieDevice(_env, conn, _id)
    end

  fun ref on_message(conn: MQTTConnection ref, packet: MQTTPacket) =>
    try (_device as HomieDevice).message(packet) end

  fun ref on_error(
    conn: MQTTConnection ref, err: MQTTError, info: String)
  =>
    _env.out.print(
      "[" +
      get_date() +
      "] " +
      err.string())
    try (_device as HomieDevice).stop() end

  fun tag get_date(): String =>
    let date = Date(Time.seconds())
    date.format("%Y-%m-%d %H:%M:%S")
