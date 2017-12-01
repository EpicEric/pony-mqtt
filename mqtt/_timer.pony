use "time"

class _MQTTPingTimer is TimerNotify
  """
  A timer for ping requests.
  """

  let _conn: MQTTConnection

  new iso create(conn: MQTTConnection) =>
    _conn = conn

  fun ref apply(timer: Timer, count: U64): Bool =>
    _conn._send_ping()
    true

class _MQTTResendTimer is TimerNotify
  """
  A timer for lost packet resends.
  """

  let _conn: MQTTConnection

  new iso create(conn: MQTTConnection) =>
    _conn = conn

  fun ref apply(timer: Timer, count: U64): Bool =>
    _conn._resend_packets()
    true

class _MQTTReconnectTimer is TimerNotify
  """
  A timer for reconnection attempts.
  """

  let _conn: MQTTConnection

  new iso create(conn: MQTTConnection) =>
    _conn = conn

  fun ref apply(timer: Timer, count: U64): Bool =>
    _conn._new_connection()
    true
