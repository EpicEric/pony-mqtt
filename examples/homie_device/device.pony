use "mqtt"
use "time"

actor HomieDevice
  let _env: Env
  let _conn: MQTTConnection
  let _id: String
  var _start_time: I64 = 0
  let _timers: Timers = Timers
  var _timer: (Timer tag | None) = None
  var uptime: U64 = 0

  new create(env: Env, conn: MQTTConnection, id: String) =>
    _env = env
    _conn = conn
    _id = id
    _startup()

  fun ref _startup() =>
    _start_time = Time.seconds()
    let timer' = Timer(HomieTimer(this), 0, 30_000_000_000)
    _timer = timer'
    _timers(consume timer')

  be publish_start() =>
    """
    Publish packets on startup.
    """
    None

  be publish_timer(count: U64) =>
    """
    Publish packets over time.
    """
    None

  be message(packet: MQTTPacket) =>
    """
    Replies to server requests.
    """
    None

  be restart() =>
    try
      _timers.cancel(_timer as Timer tag)
      _timer = None
    end
    _startup()
