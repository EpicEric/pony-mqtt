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
  let _host: String
  let base_topic: String
  let _timers: Timers = Timers
  var _start_time: I64 = 0
  var _timer_interval: (Timer tag | None) = None
  var _timer_data: (Timer tag | None) = None

  new create(
    env: Env, conn: MQTTConnection, id: String, host: String)
  =>
    _env = env
    _conn = conn
    _id = id
    _host = host
    base_topic = "homie/" + _id + "/"
    _conn.subscribe(base_topic + "disk/total_space", 1)
    _conn.subscribe(base_topic + "disk/used_space", 1)
    _conn.subscribe(base_topic + "disk/free_space", 1)
    _conn.subscribe("homie/$broadcast/#", 1)
    _startup()

  fun ref _startup(session_present: Bool = false) =>
    _kill_timers()
    _start_time = Time.seconds()
    let timer_interval' = Timer(HomieTimerInterval(this), 0, 15_000_000_000)
    _timer_interval = timer_interval'
    _timers(consume timer_interval')
    let timer_data' = Timer(HomieTimerData(this), 0, 5_000_000_000)
    _timer_data = timer_data'
    _timers(consume timer_data')
    publish_start(session_present)

  fun ref _kill_timers() =>
    try
      _timers.cancel(_timer_interval as Timer tag)
    end
    try
      _timers.cancel(_timer_data as Timer tag)
    end
    _timer_interval = None
    _timer_data = None

  be publish_start(session_present: Bool = false) =>
    """
    Publish packets on startup.
    """
    let packet_array: Array[(String, String)] =
      if session_present then
        [ (base_topic + "$online", "true") ]
      else
        [ (base_topic + "$homie", "2.1.0")
          (base_topic + "$name", "Disk size utility")
          (base_topic + "$localip", _host)
          (base_topic + "$stats/interval", "15")
          (base_topic + "$fw/name", "pony-homie-cpu")
          (base_topic + "$fw/version", "1.0")
          (base_topic + "$implementation", "pony-mqtt")
          (base_topic + "$nodes", "disk")
          (base_topic + "disk/$type", "disk")
          (base_topic + "disk/$name", "Disk")
          (base_topic + "disk/$properties", "total_space,used_space,free_space")
          (base_topic + "disk/total_space/$settable", "false")
          (base_topic + "disk/total_space/$unit", "MB")
          (base_topic + "disk/total_space/$datatype", "integer")
          (base_topic + "disk/total_space/$name", "Total space")
          (base_topic + "disk/total_space/$format", "0:4294967295")
          (base_topic + "disk/used_space/$settable", "false")
          (base_topic + "disk/used_space/$unit", "MB")
          (base_topic + "disk/used_space/$datatype", "integer")
          (base_topic + "disk/used_space/$name", "Used space")
          (base_topic + "disk/used_space/$format", "0:4294967295")
          (base_topic + "disk/free_space/$settable", "false")
          (base_topic + "disk/free_space/$unit", "MB")
          (base_topic + "disk/free_space/$datatype", "integer")
          (base_topic + "disk/free_space/$name", "Free space")
          (base_topic + "disk/free_space/$format", "0:4294967295")
          (base_topic + "$online", "true") ]
      end
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
    var total_space: U32 = 0
    var used_space: U32 = 0
    var free_space: U32 = 0
    if @pony_disk_space[Bool](
      addressof total_space, addressof used_space, addressof free_space)
    then
      _conn.publish(MQTTPacket(
        base_topic + "disk/total_space",
        total_space.string().array(),
        false,
        1))
      _conn.publish(MQTTPacket(
        base_topic + "disk/used_space",
        used_space.string().array(),
        false,
        1))
      _conn.publish(MQTTPacket(
        base_topic + "disk/free_space",
        free_space.string().array(),
        false,
        1))
    end

  be message(packet: MQTTPacket) =>
    """
    Interact with incoming messages.
    """
    None

  be stop() =>
    """
    Ends device publishing.
    """
    _kill_timers()

  be restart(session_present: Bool = false) =>
    """
    Restart the connection.
    """
    _startup(session_present)
