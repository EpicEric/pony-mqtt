use "time"

class _MQTTPingTimer is TimerNotify
  let _conn: MQTTConnection

  new iso create(conn: MQTTConnection) =>
    _conn = conn

  fun ref apply(timer: Timer, count: U64): Bool =>
    _conn.ping()
    true

class _MQTTResendTimer is TimerNotify
  let _conn: MQTTConnection

  new iso create(conn: MQTTConnection) =>
    _conn = conn

  fun ref apply(timer: Timer, count: U64): Bool =>
    _conn.resend_packets()
    true
