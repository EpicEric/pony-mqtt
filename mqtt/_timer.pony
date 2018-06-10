use "time"

class _MQTTPingTimer is TimerNotify
  """
  Timer to send PINGREQ messages to the server periodically. Currently, it
  fires at 75% of the keepalive time (i.e. if keepalive is set to 10 seconds,
  it fires every 7.5 seconds). If keepalive is set to `0`, it will fire every
  30 seconds.
  """

  let _conn: MQTTConnection

  new iso create(conn: MQTTConnection) =>
    _conn = conn

  fun ref apply(timer: Timer, count: U64): Bool =>
    _conn._send_ping()
    true

class _MQTTResendTimer is TimerNotify
  """
  Timer to handle QoS, re-firing unacknowledged PUBLISH and SUBSCRIBE requests
  with the appropriate DUP flag. Currently, it always fires every second.
  """

  let _conn: MQTTConnection

  new iso create(conn: MQTTConnection) =>
    _conn = conn

  fun ref apply(timer: Timer, count: U64): Bool =>
    _conn._resend_packets()
    true

class _MQTTReconnectTimer is TimerNotify
  """
  Timer to handle lost connections, when `reconnect_time'` is set to a value
  greater than 0. Fires at the specified interval in seconds.
  """

  let _conn: MQTTConnection

  new iso create(conn: MQTTConnection) =>
    _conn = conn

  fun ref apply(timer: Timer, count: U64): Bool =>
    _conn._new_connection()
    true
