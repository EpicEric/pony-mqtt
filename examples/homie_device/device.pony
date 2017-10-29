use "mqtt"
use "time"

use "path:lib/"
use "lib:ffi-sensor"

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
    _conn.subscribe(base_topic + "temperature/set", 1)
    _startup()

  fun ref _startup() =>
    _start_time = Time.seconds()
    let timer_interval' = Timer(HomieTimerInterval(this), 0, 15_000_000_000)
    _timer_interval = timer_interval'
    _timers(consume timer_interval')
    let timer_data' = Timer(HomieTimerData(this), 0, 500_000_000)
    _timer_data = timer_data'
    _timers(consume timer_data')
    publish_start()

  fun tag _make_buffer(size: USize): String iso^ =>
    recover String.from_cpointer(
      @pony_alloc[Pointer[U8]](@pony_ctx[Pointer[None] iso](), size), size
    ) end

  be publish_start() =>
    """
    Publish packets on startup.
    """
    let ip = _make_buffer(16)
    let mac = _make_buffer(18)
    @pony_network_address[None](ip.cpointer(), mac.cpointer())
    ip.recalc()
    mac.recalc()
    let packet_array: Array[(String, String)] =
      [ (base_topic + "$homie", "2.1.0")
        (base_topic + "$online", "true")
        (base_topic + "$name", "CPU temperature sensor")
        (base_topic + "$localip", consume ip)
        (base_topic + "$mac", consume mac)
        (base_topic + "$stats/interval", "15")
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
        (base_topic + "temperature/degrees/$format", "20.0:100.0") ]
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
    let temp = _make_buffer(7)
    @pony_cpu_temperature[None](temp.cpointer())
    temp.recalc()
    let temp_str: String = consume temp
    _conn.publish(MQTTPacket(
      base_topic + "temperature/degrees",
      temp_str.array(),
      false,
      1
    ))

  be message(packet: MQTTPacket) =>
    """
    Interact with incoming messages.
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
