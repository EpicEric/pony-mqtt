use "time"

class HomieTimer is TimerNotify
  let _device: HomieDevice

  new iso create(device: HomieDevice) =>
    _device = device

  fun ref apply(timer: Timer, count: U64): Bool =>
    _device.publish_timer(count)
    true
