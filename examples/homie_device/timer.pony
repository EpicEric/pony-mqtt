use "time"

class HomieTimerInterval is TimerNotify
  """
  A timer to fire control packets on a set interval.
  """

  let _device: HomieDevice

  new iso create(device: HomieDevice) =>
    _device = device

  fun ref apply(timer: Timer, count: U64): Bool =>
    _device.publish_timer_interval(count)
    true

class HomieTimerData is TimerNotify
  """
  A timer to collect data and send packets over time.
  """

  let _device: HomieDevice

  new iso create(device: HomieDevice) =>
    _device = device

  fun ref apply(timer: Timer, count: U64): Bool =>
    _device.publish_timer_data(count)
    true
