use "mqtt"
use "time"

actor HomieDevice
  """
  A very simple Homie-compliant device.

  More information at: https://github.com/marvinroger/homie
  """
  let _env: Env
  let _conn: MQTTConnection
  let _id: String
  let base_topic: String
  let _timers: Timers = Timers
  var _start_time: I64 = 0
  var _timer_interval: (Timer tag | None) = None
  var _timer_data: (Timer tag | None) = None

  new create(env: Env, conn: MQTTConnection, id: String) =>
    _env = env
    _conn = conn
    _id = id
    base_topic = "homie/" + _id + "/"
    _startup()

  fun ref _startup() =>
    _start_time = Time.seconds()
    let timer_interval' = Timer(HomieTimerInterval(this), 0, 10_000_000_000)
    _timer_interval = timer_interval'
    _timers(consume timer_interval')
    let timer_data' = Timer(HomieTimerData(this), 0, 500_000_000)
    _timer_data = timer_data'
    _timers(consume timer_data')
    publish_start()

  be publish_start() =>
    """
    Publish packets on startup.
    """
    let packet_array: Array[(String, String)] = [
      (base_topic + "$homie", "2.1.0")
      (base_topic + "$online", "true")
      (base_topic + "$name", "CPU temperature sensor")
      (base_topic + "$localip", "TODO")
      (base_topic + "$mac", "TODO")
      (base_topic + "$stats/interval", "10")
      (base_topic + "$fw/name", "pony-homie-cpu")
      (base_topic + "$fw/version", "1.0")
      (base_topic + "$implementation", "pony-mqtt")
      (base_topic + "$nodes", "temperature")
      (base_topic + "temperature/$type", "temperature")
      (base_topic + "temperature/$name", "CPU temperature")
      (base_topic + "temperature/$properties", "degrees")
      (base_topic + "temperature/degrees/$settable", "false")
      (base_topic + "temperature/degrees/$unit", "°C")
      (base_topic + "temperature/degrees/$datatype", "float")
      (base_topic + "temperature/degrees/$name", "Degrees")
      (base_topic + "temperature/degrees/$format", "20.0:100.0")
    ]
    for tuple in packet_array.values() do
      _conn.publish(MQTTPacket(tuple._1, tuple._2.array(), true, 1))
    end

  be publish_timer_interval(count: U64) =>
    """
    Publish control packets in an interval.
    """
    _conn.publish(MQTTPacket(
      base_topic + "$stats/uptime",
      (Time.seconds() - _start_time).string().array(),
      true,
      1
    ))

  be publish_timer_data(count: U64) =>
    """
    Publish data packets frequently.
    """
    _conn.publish(MQTTPacket(
      base_topic + "temperature/degrees",
      "TODO".array(),
      true,
      1
    ))

  be message(packet: MQTTPacket) =>
    """
    Replies to server requests.
    """
    None

  be restart() =>
    try
      _timers.cancel(_timer_interval as Timer tag)
    end
    try
      _timers.cancel(_timer_data as Timer tag)
    end
    _startup()
