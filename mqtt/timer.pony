use "time"

class _MQTTPingTimer is TimerNotify
  """
  A timer for ping requests.
  """
  let _conn: _MQTTConnection

  new iso create(conn: _MQTTConnection) =>
    _conn = conn

  fun ref apply(timer: Timer, count: U64): Bool =>
    _conn.ping()
    true

class _MQTTResendTimer is TimerNotify
  """
  A timer for lost packet resends.
  """
  let _conn: _MQTTConnection

  new iso create(conn: _MQTTConnection) =>
    _conn = conn

  fun ref apply(timer: Timer, count: U64): Bool =>
    _conn.resend_packets()
    true
