use "mqtt"
use "net"
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

  fun ref on_connect(
    conn: MQTTConnectionInterface ref, session_present: Bool)
  =>
    match _device
    | None =>
      _env.out.print(
        "[" +
        get_date() +
        "] Connected.")
      let host = 
        try
          conn.local_address()?.name()?._1
        else
          "unknown"
        end
      _device = HomieDevice(_env, conn, _id, host)
    | let d: HomieDevice =>
      _env.out.print(
        "[" +
        get_date() +
        "] Reconnected.")
      d.restart(session_present)
    end

  fun ref on_message(conn: MQTTConnectionInterface ref, packet: MQTTPacket) =>
    try (_device as HomieDevice).message(packet) end

  fun ref on_error(
    conn: MQTTConnectionInterface ref, err: MQTTError, info: Array[U8] val)
  =>
    _env.out.print(
      "<ERROR> [" +
      get_date() +
      "] " +
      err.string())
    try (_device as HomieDevice).stop() end

  fun tag get_date(): String =>
    try
      let date = PosixDate(Time.seconds())
      date.format("%Y-%m-%d %H:%M:%S")?
    else "???" end

