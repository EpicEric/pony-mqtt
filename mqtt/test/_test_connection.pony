use "files"
use "format"
use "net"
use "net/ssl"
use "ponytest"

use ".."

actor _TestConnection is TestList
  """
  Integration tests that verify different functionalities of the
  MQTTConnection actor when connecting to a server.
  """

  fun tag tests(test: PonyTest) =>
    test(_TestConnectionConnect)
    test(_TestConnectionConnectTLS)
    test(_TestConnectionUnacceptedVersion)
    test(_TestConnectionAuthentication)
    test(_TestConnectionAuthenticationError)
    test(_TestConnectionWillPacket)
    test(_TestConnectionCleanSession)
    test(_TestConnectionNoCleanSession)
    test(_TestConnectionPublishSend)
    test(_TestConnectionPublishReceive)
    test(_TestConnectionSubscribe)
    test(_TestConnectionUnsubscribe)
    test(_TestConnectionDisconnect)
    test(_TestConnectionPing)
    test(_TestConnectionReconstructMessage)

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
  var _sslctx: (SSLContext | None) = None
  var _sslhost: String = ""
  var _version: MQTTVersion = MQTTv311
  var _retry_connection: U64 = 0
  var _clean_session: Bool = true
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
    sslctx: (SSLContext | None) = None,
    sslhost: String = "",
    version: MQTTVersion = MQTTv311,
    retry_connection: U64 = 0,
    clean_session: Bool = true,
    will_packet: (MQTTPacket | None) = None,
    client_id: String = "",
    user: (String | None) = None,
    pass: (String | None) = None,
    long_test: U64 = 2_000_000_000)
  =>
    _client = consume client
    _server = consume server
    _server_retry = consume server_retry
    _keepalive = keepalive
    _sslctx = sslctx
    _sslhost = sslhost
    _version = version
    _retry_connection = retry_connection
    _clean_session = clean_session
    _will_packet = will_packet
    _client_id = client_id
    _user = user
    _pass = pass
    let h = _h
    h.expect_action("server create")
    h.expect_action("server listen")
    h.expect_action("client create")
    h.expect_action("server accept")
    if not(_server_retry is None) then
      h.expect_action("server accept retry")
    end
    try
      let auth = h.env.root as AmbientAuth
      h.dispose_when_done(TCPListener(auth, consume this))
      h.complete_action("server create")
    else
      h.fail_action("server create")
    end
    h.long_test(long_test.max(2_000_000_000))

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
        _clean_session,
        _sslctx,
        _sslhost,
        _will_packet,
        _client_id,
        _user,
        _pass))
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
      if not(_sslctx is None) then
        let ssl = (_sslctx as SSLContext).server()?
        SSLConnection(consume notify, consume ssl)
      else
        consume notify
      end
    else
      _h.fail("server accept")
      error
    end

class iso _TestConnectionConnect is UnitTest
  """
  Attempt a basic connection to an MQTT server.
  """

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

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _h.complete_action("mqtt connack")

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")

class _TestConnectionConnectServer is TCPConnectionNotify
  let _h: TestHelper
  let _data_buffer: Array[U8] = Array[U8]

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    _data_buffer.append(consume data)
    while _data_buffer.size() >= 2 do
      try
        let size = _data_buffer(1)?.usize()
        if size <= _data_buffer.size() then
          _h.assert_eq[U8](_data_buffer(0)?, 0x10)
          _data_buffer.trim_in_place(size)
          _h.complete_action("mqtt connect")
          conn.write([ 0x20; 0x02; 0x00; 0x00 ])
        else break end
      else
        _h.fail_action("mqtt connect")
      end
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")

class iso _TestConnectionConnectTLS is UnitTest
  """
  Attempt a TLS connection to an MQTT server.
  """

  fun name(): String =>
    "MQTT/Connection/ConnectTLS"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) ? =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    let auth = h.env.root as AmbientAuth
    let cert: FilePath = try
      FilePath(auth, "./mqtt/test/cert.pem")?
    else
      h.fail("cert.pem")
      error
    end
    let key: FilePath = try
      FilePath(auth, "./mqtt/test/key.pem")?
    else
      h.fail("key.pem")
      error
    end
    let sslctx: SSLContext =
      recover
        let ctx = SSLContext
        try
          ctx.set_authority(cert)?
        else
          h.fail("ctx.set_authority()")
          error
        end
        try
          ctx.set_cert(cert, key)?
        else
          h.fail("ctx.set_cert()")
          error
        end
        ctx.set_client_verify(true)
        ctx.set_server_verify(true)
        ctx
      end
    _TestConnectionListenNotify(h)(
      _TestConnectionConnectClient(h),
      _TestConnectionConnectServer(h)
      where sslctx = sslctx,
      sslhost = "")

class iso _TestConnectionUnacceptedVersion is UnitTest
  """
  Fails on first connection to server due to unsupported protocol version 3.1.1,
  and retries with version 3.1, which is successful.
  """

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
  var _first_try: Bool

  new iso create(h: TestHelper) =>
    _h = h
    _first_try = true

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _h.assert_false(_first_try)
    _h.complete_action("mqtt connack good")

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.assert_true(_first_try)
    _first_try = false
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
        _h.assert_eq[U8](match_array(i)?, buffer(version_pos + i)?)
      end
      _h.complete_action("mqtt connect good")
      conn.write([ 0x20; 0x02; 0x00; 0x00 ])
    else
      _h.fail_action("mqtt connect good")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect good")

class iso _TestConnectionAuthentication is UnitTest
  fun name(): String =>
    "MQTT/Connection/Authentication"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    _TestConnectionListenNotify(h)(
      _TestConnectionConnectClient(h),
      _TestConnectionAuthenticationServer(h)
      where user = "pony",
      pass = "horse",
      client_id = "00000000",
      version = MQTTv311)

class _TestConnectionAuthenticationServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    var buffer: Array[U8] val = consume data
    try
      _h.assert_eq[U8](buffer(0)?, 0x10)
      var version_pos: USize = 1
      while (buffer(version_pos)? and 0x80) == 0x80 do
        version_pos = version_pos + 1
      end
      version_pos = version_pos + 1
      buffer = buffer.trim(version_pos + 7) // Remove everything prior to flags
      _h.assert_eq[U8](buffer(0)? and 0xC0, 0xC0) // Check flags
      buffer = buffer.trim(13) // Remove rest of variable header + client ID
      let match_array: Array[U8] val =
        recover
          [ 0; 4; 'p'; 'o'; 'n'; 'y'
            0; 5; 'h'; 'o'; 'r'; 's'; 'e' ]
        end
      for i in match_array.keys() do
        _h.assert_eq[U8](match_array(i)?, buffer(i)?)
      end
      _h.complete_action("mqtt connect")
      conn.write([ 0x20; 0x02; 0x00; 0x00 ])
    else
      _h.fail_action("mqtt connect")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")

class iso _TestConnectionAuthenticationError is UnitTest
  fun name(): String =>
    "MQTT/Connection/AuthenticationError"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect bad")
    h.expect_action("mqtt connack bad")
    _TestConnectionListenNotify(h)(
      _TestConnectionAuthenticationErrorClient(h),
      _TestConnectionAuthenticationErrorServer(h)
      where user = "pony",
      pass = "unicorn",
      client_id = "00000000",
      version = MQTTv311,
      will_packet = None)

class _TestConnectionAuthenticationErrorClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _h.fail_action("mqtt connack bad")

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    if err is MQTTErrorConnectAuthentication then
      _h.complete_action("mqtt connack bad")
    else
      _h.fail_action("mqtt connack bad")
    end

class _TestConnectionAuthenticationErrorServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    var buffer: Array[U8] val = consume data
    try
      _h.assert_eq[U8](buffer(0)?, 0x10)
      var version_pos: USize = 1
      while (buffer(version_pos)? and 0x80) == 0x80 do
        version_pos = version_pos + 1
      end
      version_pos = version_pos + 1
      buffer = buffer.trim(version_pos + 7) // Remove everything prior to flags
      _h.assert_eq[U8](buffer(0)? and 0xC0, 0xC0) // Check flags
      buffer = buffer.trim(13) // Remove rest of variable header + client ID
      let match_array: Array[U8] val =
        recover
          [ 0; 4; 'p'; 'o'; 'n'; 'y'
            0; 5; 'h'; 'o'; 'r'; 's'; 'e' ]
        end
      for i in match_array.keys() do
        if match_array(i)? != buffer(i)? then
          _h.complete_action("mqtt connect bad")
          conn.write([ 0x20; 0x02; 0x00; 0x04 ])
          return true
        end
      end
      _h.fail_action("mqtt connect bad")
    else
      _h.fail_action("mqtt connect bad")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect bad")


class iso _TestConnectionWillPacket is UnitTest
  fun name(): String =>
    "MQTT/Connection/WillPacket"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    _TestConnectionListenNotify(h)(
      _TestConnectionConnectClient(h),
      _TestConnectionWillPacketServer(h)
      where will_packet = MQTTPacket("$pony/set", "My test".array(), true, 2),
      client_id = "00000000",
      version = MQTTv311)

class _TestConnectionWillPacketServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    var buffer: Array[U8] val = consume data
    try
      _h.assert_eq[U8](buffer(0)?, 0x10)
      var version_pos: USize = 1
      while (buffer(version_pos)? and 0x80) == 0x80 do
        version_pos = version_pos + 1
      end
      version_pos = version_pos + 1
      buffer = buffer.trim(version_pos + 7) // Remove everything prior to flags
      _h.assert_eq[U8](buffer(0)? and 0x3C, 0x34) // Check flags
      buffer = buffer.trim(13) // Remove rest of variable header + client ID
      let match_array: Array[U8] val =
        recover
          [ 0; 9; '$'; 'p'; 'o'; 'n'; 'y' ; '/' ; 's'; 'e'; 't'
            0; 7; 'M'; 'y'; ' '; 't'; 'e'; 's'; 't' ]
        end
      for i in match_array.keys() do
        _h.assert_eq[U8](match_array(i)?, buffer(i)?)
      end
      _h.complete_action("mqtt connect")
      conn.write([ 0x20; 0x02; 0x00; 0x00 ])
    else
      _h.fail_action("mqtt connect")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")

class iso _TestConnectionCleanSession is UnitTest
  fun name(): String =>
    "MQTT/Connection/CleanSession"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    _TestConnectionListenNotify(h)(
      _TestConnectionCleanSessionClient(h),
      _TestConnectionCleanSessionServer(h)
      where clean_session = true,
      client_id = "00000000",
      version = MQTTv311)

class _TestConnectionCleanSessionClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    if not session_present then
      _h.complete_action("mqtt connack")
    else
      _h.fail_action("mqtt connack")
    end

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")

class _TestConnectionCleanSessionServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    var buffer: Array[U8] val = consume data
    try
      _h.assert_eq[U8](buffer(0)?, 0x10)
      var version_pos: USize = 1
      while (buffer(version_pos)? and 0x80) == 0x80 do
        version_pos = version_pos + 1
      end
      version_pos = version_pos + 1
      buffer = buffer.trim(version_pos + 7) // Remove everything prior to flags
      _h.assert_eq[U8](buffer(0)? and 0x02, 0x02) // Check Clean Session flag
      _h.complete_action("mqtt connect")
      conn.write([ 0x20; 0x02; 0x00; 0x00 ])
    else
      _h.fail_action("mqtt connect")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")

class iso _TestConnectionNoCleanSession is UnitTest
  fun name(): String =>
    "MQTT/Connection/NoCleanSession"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    _TestConnectionListenNotify(h)(
      _TestConnectionNoCleanSessionClient(h),
      _TestConnectionNoCleanSessionServer(h)
      where clean_session = false,
      client_id = "00000000",
      version = MQTTv311)

class _TestConnectionNoCleanSessionClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    if session_present then
      _h.complete_action("mqtt connack")
    else
      _h.fail_action("mqtt connack")
    end

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")

class _TestConnectionNoCleanSessionServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    var buffer: Array[U8] val = consume data
    try
      _h.assert_eq[U8](buffer(0)?, 0x10)
      var version_pos: USize = 1
      while (buffer(version_pos)? and 0x80) == 0x80 do
        version_pos = version_pos + 1
      end
      version_pos = version_pos + 1
      buffer = buffer.trim(version_pos + 7) // Remove everything prior to flags
      _h.assert_eq[U8](buffer(0)? and 0x02, 0x00) // Check Clean Session flag
      _h.complete_action("mqtt connect")
      conn.write([ 0x20; 0x02; 0x01; 0x00 ])
    else
      _h.fail_action("mqtt connect")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")

class iso _TestConnectionPublishSend is UnitTest
  fun name(): String =>
    "MQTT/Connection/PublishSend"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    h.expect_action("mqtt publish")
    h.expect_action("mqtt puback")
    _TestConnectionListenNotify(h)(
      _TestConnectionPublishSendClient(h),
      _TestConnectionPublishSendServer(h))

class _TestConnectionPublishSendClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _h.complete_action("mqtt connack")
    conn.publish(MQTTPacket("$pony/set", "My test".array(), true, 0))

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")

  fun ref on_publish(conn: MQTTConnection ref, packet: MQTTPacket) =>
    _h.complete_action("mqtt puback")

class _TestConnectionPublishSendServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    var buffer: Array[U8] val = consume data
    try
      match buffer(0)? and 0xF0
      | 0x10 =>
        _h.complete_action("mqtt connect")
        conn.write([ 0x20; 0x02; 0x00; 0x00 ])
      | 0x30 =>
        _h.assert_eq[U8](buffer(0)? and 0x06, 0x00) // QoS
        _h.assert_eq[U8](buffer(0)? and 0x01, 0x01) // RETAIN
        var version_pos: USize = 1
        while (buffer(version_pos)? and 0x80) == 0x80 do
          version_pos = version_pos + 1
        end
        version_pos = version_pos + 1
        buffer = buffer.trim(version_pos) // Remove remaining length
        let match_array: Array[U8] val =
          recover
            [ 0; 9; '$'; 'p'; 'o'; 'n'; 'y'; '/'; 's'; 'e'; 't' ]
          end
        for i in match_array.keys() do
          _h.assert_eq[U8](match_array(i)?, buffer(i)?)
        end
        buffer = buffer.trim(match_array.size()) // Remove topic
        let match_array_2: Array[U8] val =
          recover
            [ 'M'; 'y'; ' '; 't'; 'e'; 's'; 't' ]
          end
        _h.assert_eq[USize](buffer.size(), match_array_2.size())
        for i in match_array_2.keys() do
          _h.assert_eq[U8](match_array_2(i)?, buffer(i)?)
        end
        _h.complete_action("mqtt publish")
      else
        _h.fail("unknown packet")
      end
    else
      _h.fail_action("mqtt connect")
      _h.fail_action("mqtt publish")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")

class iso _TestConnectionPublishReceive is UnitTest
  fun name(): String =>
    "MQTT/Connection/PublishReceive"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    h.expect_action("mqtt publish")
    _TestConnectionListenNotify(h)(
      _TestConnectionPublishReceiveClient(h),
      _TestConnectionPublishReceiveServer(h))

class _TestConnectionPublishReceiveClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _h.complete_action("mqtt connack")

  fun ref on_message(conn: MQTTConnection ref, packet: MQTTPacket) =>
    _h.assert_eq[String](packet.topic, "$pony/set")
    let message: String = recover String.from_array(packet.message) end
    _h.assert_eq[String](message, "My test")
    _h.complete_action("mqtt publish")

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")
    _h.fail_action("mqtt publish")

class _TestConnectionPublishReceiveServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    var buffer: Array[U8] val = consume data
    try
      _h.assert_eq[U8](buffer(0)?, 0x10)
      _h.complete_action("mqtt connect")
      conn.write([ 0x20; 0x02; 0x00; 0x00 ])
      conn.write(
        [ 0x31; 0x12; 0x00; 0x09; '$'; 'p'; 'o'; 'n'; 'y'; '/'
          's'; 'e'; 't'; 'M'; 'y'; ' '; 't'; 'e'; 's'; 't' ]
      )
    else
      _h.fail_action("mqtt connect")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")

class iso _TestConnectionSubscribe is UnitTest
  fun name(): String =>
    "MQTT/Connection/Subscribe"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    h.expect_action("mqtt subscribe")
    h.expect_action("mqtt suback")
    _TestConnectionListenNotify(h)(
      _TestConnectionSubscribeClient(h),
      _TestConnectionSubscribeServer(h))

class _TestConnectionSubscribeClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _h.complete_action("mqtt connack")
    conn.subscribe("$pony/#", 1)

  fun ref on_subscribe(conn: MQTTConnection ref, topic: String, qos: U8) =>
    _h.assert_eq[String](topic, "$pony/#")
    _h.assert_eq[U8](qos, 1)
    _h.complete_action("mqtt suback")

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")

class _TestConnectionSubscribeServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    var buffer: Array[U8] val = consume data
    try
      match buffer(0)?
      | 0x10 =>
        _h.complete_action("mqtt connect")
        conn.write([ 0x20; 0x02; 0x00; 0x00 ])
      | 0x82 =>
        var version_pos: USize = 1
        while (buffer(version_pos)? and 0x80) == 0x80 do
          version_pos = version_pos + 1
        end
        version_pos = version_pos + 1
        buffer = buffer.trim(version_pos) // Remove remaining length
        let packet_id_msb: U8 = buffer(0)?
        let packet_id_lsb: U8 = buffer(1)?
        buffer = buffer.trim(2) // Remove packet ID
        let match_array: Array[U8] val =
          recover
            [ 0; 7; '$'; 'p'; 'o'; 'n'; 'y'; '/'; '#'; 1 ]
          end
        for i in match_array.keys() do
          _h.assert_eq[U8](match_array(i)?, buffer(i)?)
        end
        _h.complete_action("mqtt subscribe")
        conn.write(
          [ 0x90; 3; packet_id_msb; packet_id_lsb; 0x01 ]
        )
      else
        _h.fail("unknown packet")
      end
    else
      _h.fail_action("mqtt connect")
      _h.fail_action("mqtt subscribe")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")
    _h.fail_action("mqtt subscribe")

class iso _TestConnectionUnsubscribe is UnitTest
  fun name(): String =>
    "MQTT/Connection/Unsubscribe"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    h.expect_action("mqtt unsubscribe")
    h.expect_action("mqtt unsuback")
    _TestConnectionListenNotify(h)(
      _TestConnectionUnsubscribeClient(h),
      _TestConnectionUnsubscribeServer(h))

class _TestConnectionUnsubscribeClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _h.complete_action("mqtt connack")
    conn.unsubscribe("$pony/#")

  fun ref on_unsubscribe(conn: MQTTConnection ref, topic: String) =>
    _h.assert_eq[String](topic, "$pony/#")
    _h.complete_action("mqtt unsuback")

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")

class _TestConnectionUnsubscribeServer is TCPConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    var buffer: Array[U8] val = consume data
    try
      match buffer(0)?
      | 0x10 =>
        _h.complete_action("mqtt connect")
        conn.write([ 0x20; 0x02; 0x00; 0x00 ])
      | 0xA2 =>
        var version_pos: USize = 1
        while (buffer(version_pos)? and 0x80) == 0x80 do
          version_pos = version_pos + 1
        end
        version_pos = version_pos + 1
        buffer = buffer.trim(version_pos) // Remove remaining length
        let packet_id_msb: U8 = buffer(0)?
        let packet_id_lsb: U8 = buffer(1)?
        buffer = buffer.trim(2) // Remove packet ID
        let match_array: Array[U8] val =
          recover
            [ 0; 7; '$'; 'p'; 'o'; 'n'; 'y'; '/'; '#' ]
          end
        for i in match_array.keys() do
          _h.assert_eq[U8](match_array(i)?, buffer(i)?)
        end
        _h.complete_action("mqtt unsubscribe")
        conn.write(
          [ 0xB0; 2; packet_id_msb; packet_id_lsb ]
        )
      else
        _h.fail("unknown packet")
      end
    else
      _h.fail_action("mqtt connect")
      _h.fail_action("mqtt unsubscribe")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")
    _h.fail_action("mqtt unsubscribe")

class iso _TestConnectionDisconnect is UnitTest
  fun name(): String =>
    "MQTT/Connection/Disconnect"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    h.expect_action("mqtt disconnect")
    h.expect_action("mqtt disconnack")
    _TestConnectionListenNotify(h)(
      _TestConnectionDisconnectClient(h),
      _TestConnectionDisconnectServer(h))

class _TestConnectionDisconnectClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _h.complete_action("mqtt connack")
    conn.disconnect()

  fun ref on_disconnect(conn: MQTTConnection ref) =>
    _h.complete_action("mqtt disconnack")

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")

class _TestConnectionDisconnectServer is TCPConnectionNotify
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
      match buffer(0)?
      | 0x10 =>
        _h.complete_action("mqtt connect")
        conn.write([ 0x20; 0x02; 0x00; 0x00 ])
      | 0xE0 =>
        _h.assert_eq[U8](buffer(1)?, 0x00)
        _h.assert_eq[USize](buffer.size(), 2)
        _h.complete_action("mqtt disconnect")
        conn.close()
      else
        _h.fail("unknown packet")
      end
    else
      _h.fail_action("mqtt connect")
      _h.fail_action("mqtt disconnect")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")

class iso _TestConnectionPing is UnitTest
  fun name(): String =>
    "MQTT/Connection/Ping"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    h.expect_action("mqtt pingreq")
    h.expect_action("mqtt pingresp")
    _TestConnectionListenNotify(h)(
      _TestConnectionPingClient(h),
      _TestConnectionPingServer(h)
      where keepalive = 5,
      long_test = 5_000_000_000)

class _TestConnectionPingClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _h.complete_action("mqtt connack")

  fun ref on_ping(conn: MQTTConnection ref) =>
    _h.complete_action("mqtt pingresp")

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")

class _TestConnectionPingServer is TCPConnectionNotify
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
      match buffer(0)?
      | 0x10 =>
        _h.complete_action("mqtt connect")
        conn.write([ 0x20; 0x02; 0x00; 0x00 ])
      | 0xC0 =>
        _h.complete_action("mqtt pingreq")
        conn.write([ 0xD0; 0x00 ])
      else
        _h.fail("unknown packet")
      end
    else
      _h.fail_action("mqtt connect")
      _h.fail_action("mqtt pingreq")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")

class iso _TestConnectionReconstructMessage is UnitTest
  fun name(): String =>
    "MQTT/Connection/ReconstructMessage"

  fun label(): String =>
    "connection"

  fun exclusion_group(): String =>
    "network"

  fun ref apply(h: TestHelper) =>
    h.expect_action("mqtt connect")
    h.expect_action("mqtt connack")
    h.expect_action("mqtt subscribe")
    h.expect_action("mqtt suback")
    h.expect_action("mqtt publish 1")
    h.expect_action("mqtt publish 2")
    _TestConnectionListenNotify(h)(
      _TestConnectionReconstructMessageClient(h),
      _TestConnectionReconstructMessageServer(h))

class _TestConnectionReconstructMessageClient is MQTTConnectionNotify
  let _h: TestHelper

  new iso create(h: TestHelper) =>
    _h = h

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _h.complete_action("mqtt connack")
    conn.subscribe("#")

  fun ref on_subscribe(conn: MQTTConnection ref, topic: String, qos: U8) =>
    _h.complete_action("mqtt suback")

  fun ref on_message(conn: MQTTConnection ref, packet: MQTTPacket) =>
    match packet.topic
    | "publish/1" =>
      _h.complete_action("mqtt publish 1")
    | "publish/2" =>
      _h.complete_action("mqtt publish 2")
    else
      _h.fail("mqtt publish")
    end

  fun ref on_error(conn: MQTTConnection ref, err: MQTTError, info: String) =>
    _h.fail_action("mqtt connack")

class _TestConnectionReconstructMessageServer is TCPConnectionNotify
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
      match buffer(0)?
      | 0x10 =>
        _h.complete_action("mqtt connect")
        conn.write([ 0x20; 0x02; 0x00; 0x00 ])
      | 0x82 =>
        var version_pos: USize = 1
        while (buffer(version_pos)? and 0x80) == 0x80 do
          version_pos = version_pos + 1
        end
        version_pos = version_pos + 1
        let packet_id_msb: U8 = buffer(version_pos)?
        let packet_id_lsb: U8 = buffer(version_pos + 1)?
        _h.complete_action("mqtt subscribe")
        conn.write(
          [ // Subscribe
            0x90; 0x03; packet_id_msb; packet_id_lsb; 0x00
            // Part 1/2 of Publish 1
            0x31; 0x0B; 0x00; 0x09; 'p'; 'u'; 'b'; 'l'; 'i'; 's'; 'h' ]
        )
        conn.write(
          [ // Part 2/2 of Publish 1
            '/'; '1'
            // Publish 2
            0x31; 0x0B; 0x00; 0x09; 'p'; 'u'
            'b'; 'l'; 'i'; 's'; 'h'; '/'; '2' ]
        )
      else
        _h.fail("unknown packet")
      end
    else
      _h.fail_action("mqtt connect")
      _h.fail_action("mqtt subscribe")
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _h.fail_action("mqtt connect")
