use "ponytest"
use "net"

actor _TestConnection is TestList
  fun tag tests(test: PonyTest) =>
    test(_TestConnectionConnect)
    test(_TestConnectionUnacceptedVersion)

class _TestConnectionListenNotify is TCPListenNotify
  """
  Runs a test MQTT client and broker server on a dynamically available
  TCP port.
  """
  let _h: TestHelper
  var _client: (MQTTConnectionNotify iso | None) = None
  var _server: (TCPConnectionNotify iso | None) = None
  var _server_retry: (TCPConnectionNotify iso | None) = None
  var _keepalive: U16 = 15
  var _version: MQTTVersion = MQTTv311
  var _retry_connection: U64 = 0
  var _will_packet: (MQTTPacket | None) = None
  var _client_id: String = ""
  var _user: (String | None) = None
  var _pass: (String | None) = None

  new iso create(h: TestHelper) =>
    _h = h

  fun iso apply(
    client: MQTTConnectionNotify iso,
    server: TCPConnectionNotify iso,
    server_retry: (TCPConnectionNotify iso | None) = None,
    keepalive: U16 = 15,
    version: MQTTVersion = MQTTv311,
    retry_connection: U64 = 0,
    will_packet: (MQTTPacket | None) = None,
    client_id: String = "",
    user: (String | None) = None,
    pass: (String | None) = None)
  =>
    _client = consume client
    _server = consume server
    _server_retry = consume server_retry
    _keepalive = keepalive
    _version = version
    _retry_connection = retry_connection
    _will_packet = will_packet
    _client_id = client_id
    _user = user
    _pass = pass
    let h = _h
    h.expect_action("server create")
    h.expect_action("server listen")
    h.expect_action("client create")
    h.expect_action("server accept")
    if _server_retry isnt None then
      h.expect_action("server accept retry")
    end
    try
      let auth = h.env.root as AmbientAuth
      h.dispose_when_done(TCPListener(auth, consume this))
      h.complete_action("server create")
    else
      h.fail_action("server create")
    end
    h.long_test(2_000_000_000)

  fun ref not_listening(listen: TCPListener ref) =>
    _h.fail_action("server listen")

  fun ref listening(listen: TCPListener ref) =>
    _h.complete_action("server listen")
    try
      let auth = _h.env.root as AmbientAuth
      (let host, let port) = listen.local_address().name()?
      _h.dispose_when_done(MQTTConnection(
        auth,
        (_client = None) as MQTTConnectionNotify iso^,
        host,
        port,
        _keepalive,
        _version,
        _retry_connection,
        _will_packet,
        _client_id,
        _user,
        _pass
      ))
      _h.complete_action("client create")
    else
      _h.fail_action("client create")
    end

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ ? =>
    try
      let notify = (_server = _server_retry = None) as TCPConnectionNotify iso^
      if _server is None then
        _h.complete_action("server accept")
      else
        _h.complete_action("server accept retry")
      end
      consume notify
    else
      _h.fail("server accept")
      error
    end

class iso _TestConnectionConnect is UnitTest
  fun name(): String =>
    "MQTT/Connection/Connect"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    _TestConnectionListenNotify(h)(
      _TestConnectionConnectClient(h),
      _TestConnectionConnectServer(h))

class _TestConnectionConnectClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref) =>
    _h.complete_action("mqtt connack")

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")

class _TestConnectionConnectServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    let buffer: Array[U8] val = consume data
    try
      _h.assert_eq[U8](buffer(0)?, 0x10)
      _h.complete_action("mqtt connect")
      conn.write([ 0x20; 0x02; 0x00; 0x00 ])
    else
      _h.fail_action("mqtt connect")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")

class iso _TestConnectionUnacceptedVersion is UnitTest
  fun name(): String =>
    "MQTT/Connection/UnacceptedVersion"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect bad")
    h.expect_action("mqtt connack bad")
    h.expect_action("mqtt connect good")
    h.expect_action("mqtt connack good")
    _TestConnectionListenNotify(h)(
      _TestConnectionUnacceptedVersionClient(h),
      _TestConnectionUnacceptedVersionServer(h),
      _TestConnectionUnacceptedVersionServerRetry(h)
      where retry_connection = 1,
      version = MQTTv311)

class _TestConnectionUnacceptedVersionClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref) =>
    _h.complete_action("mqtt connack good")

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.assert_is[MQTTError](err, MQTTErrorConnectProtocolRetry)
    _h.complete_action("mqtt connack bad")

class _TestConnectionUnacceptedVersionServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    let buffer: Array[U8] val = consume data
    try
      _h.assert_eq[U8](buffer(0)?, 0x10)
      var version_pos: USize = 1
      while (buffer(version_pos)? and 0x80) == 0x80 do
        version_pos = version_pos + 1
      end
      version_pos = version_pos + 1
      let match_array: Array[U8] val =
        recover
          [ 0x00; 0x06; 'M'; 'Q'; 'I'; 's'; 'd'; 'p'; 0x03 ]
        end
      for i in match_array.keys() do
        if match_array(i)? != buffer(version_pos + i)? then
          _h.complete_action("mqtt connect bad")
          conn.write([ 0x20; 0x02; 0x00; 0x01 ])
          conn.dispose()
          return true
        end
      end
    end
    _h.fail_action("mqtt connect bad")
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect bad")

class _TestConnectionUnacceptedVersionServerRetry is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    let buffer: Array[U8] val = consume data
    try
      _h.assert_eq[U8](buffer(0)?, 0x10)
      var version_pos: USize = 1
      while (buffer(version_pos)? and 0x80) == 0x80 do
        version_pos = version_pos + 1
      end
      version_pos = version_pos + 1
      let match_array: Array[U8] val =
        recover
          [ 0x00; 0x06; 'M'; 'Q'; 'I'; 's'; 'd'; 'p'; 0x03 ]
        end
      for i in match_array.keys() do
        if match_array(i)? != buffer(version_pos + i)? then
          _h.fail_action("mqtt connect good")
          return true
        end
      end
      _h.complete_action("mqtt connect good")
      conn.write([ 0x20; 0x02; 0x00; 0x00 ])
    else
      _h.fail_action("mqtt connect good")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect good")
