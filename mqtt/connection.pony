use "buffered"
use "collections"
use "net"
use "net/ssl"
use "time"

actor MQTTConnection
  """
  An actor that handles the entire MQTT connection.

  It can receive data through an _MQTTConnectionHandler, or commands from an
  MQTTConnectionNotify. This allows for all expected capabilities of
  a regular MQTT client.
  """

  let auth: AmbientAuth
  let host: String
  let port: String
  let _client: MQTTConnectionNotify
  let _keepalive: U16
  let _user: (String | None)
  let _pass: (String | None)
  let _retry_connection: Bool
  let _sslctx: (SSLContext | None)
  let _sslhost: String
  let _will_packet: (MQTTPacket | None)
  let _ping_time: U64
  let _resend_time: U64
  let _reconnect_time: U64
  let _timers: Timers = Timers
  let _unimplemented: Map[U8, String] = _unimplemented.create()
  let _sent_packets: Map[U16, MQTTPacket] = _sent_packets.create()
  let _received_packets: Map[U16, MQTTPacket] = _received_packets.create()
  let _confirmed_packets: Map[U16, MQTTPacket] = _confirmed_packets.create()
  let _sub_topics: Map[U16, (String, U8)] = _sub_topics.create()
  let _unsub_topics: Map[U16, String] = _unsub_topics.create()
  var _version: MQTTVersion
  var _client_id: String
  var _is_connected: Bool = false
  var _conn: (TCPConnection | None) = None
  var _packet_id: U16 = 0
  var _ping_timer: (Timer tag | None) = None
  var _resend_timer: (Timer tag | None) = None
  var _reconnect_timer: (Timer tag | None) = None

  new create(
    auth': AmbientAuth,
    notify': MQTTConnectionNotify iso,
    host': String,
    port': String = "1883",
    keepalive': U16 = 15,
    version': MQTTVersion = MQTTv311,
    retry_connection': U64 = 0,
    sslctx': (SSLContext | None) = None,
    sslhost': String = "",
    will_packet': (MQTTPacket | None) = None,
    client_id': String = "",
    user': (String | None) = None,
    pass': (String | None) = None)
  =>
    auth = auth'
    host = host'
    port = port'
    _client = consume notify'
    _keepalive = keepalive'.max(5)
    _version = version'
    _user =
      try
        if (user' as String).size() > 0 then user' else None end
      else None end
    _pass =
      try
        if (pass' as String).size() > 0 then pass' else None end
      else None end
    if retry_connection' > 0 then
      _retry_connection = true
      _reconnect_time = 1_000_000_000 * retry_connection'
    else
      _retry_connection = false
      _reconnect_time = 0
    end
    _sslctx = sslctx'
    _sslhost = sslhost'
    _will_packet =
      try
        let wp = will_packet' as MQTTPacket
        if not MQTTTopic.validate_publish(wp.topic) then
          None
        else
          wp
        end
      else
        None
      end
    _client_id = 
      if client_id'.size() >= 6 then
        client_id'
      else
        MQTTUtils.random_string() 
      end
    _ping_time = 750_000_000 * _keepalive.u64()
    _resend_time = 1_000_000_000
    _update_version(version')
    _new_connection()

  be _connected(
    conn: TCPConnection,
    notify: _MQTTConnectionHandler tag)
  =>
    _end_connection(false)
    try
      _timers.cancel(_reconnect_timer as Timer tag)
    end
    _reconnect_timer = None
    _conn = conn
    _connect()

  be _connect_failed(
    conn: TCPConnection,
    notify: _MQTTConnectionHandler tag)
  =>
    if _is_connected and _retry_connection then
      _client.on_error(this, MQTTErrorConnectFailedRetry)
      let reconnect_timer = Timer(
        _MQTTReconnectTimer(this), _reconnect_time, _reconnect_time)
      _reconnect_timer = reconnect_timer
      _timers(consume reconnect_timer)
    else
      _end_connection()
      _client.on_error(this, MQTTErrorConnectFailed)
    end

  be _closed(
    conn: TCPConnection,
    notify: _MQTTConnectionHandler tag)
  =>
    if _is_connected then
      if _retry_connection then
        _client.on_error(this, MQTTErrorSocketRetry)
        let reconnect_timer = Timer(
          _MQTTReconnectTimer(this), 0, _reconnect_time)
        _reconnect_timer = reconnect_timer
        _timers(consume reconnect_timer)
      else
        _end_connection()
        _client.on_error(this, MQTTErrorSocket)
      end
    else
      _end_connection()
      _client.on_disconnect(this)
    end

  be _parse_packet(
    conn: TCPConnection,
    notify: _MQTTConnectionHandler tag,
    data: Array[U8] val)
  =>
    """
    Parses and acts according to a single control packet.
    """
    let buffer = Reader
    buffer.append(data)
    try
      if not(_is_connected) and (buffer.peek_u8(0)? != 0x20) then return end
      match buffer.peek_u8(0)? >> 4
      | 0x2 => // CONNACK
        if buffer.peek_u8(0)? != 0x20 then error end
        if buffer.size() != 4 then error end
        match buffer.peek_u8(3)? // Return code
        | 0 =>
          _is_connected = true
          // Create a package resender timer and a keepalive timer
          _clean_timers()
          let resend_timer = Timer(
            _MQTTPingTimer(this), _ping_time, _ping_time)
          _resend_timer = resend_timer
          _timers(consume resend_timer)
          let ping_timer = Timer(
            _MQTTResendTimer(this), _resend_time, _resend_time)
          _ping_timer = ping_timer
          _timers(consume ping_timer)
          _client.on_connect(this)
        | 1 =>
          if _retry_connection and not(_version is MQTTv31) then
            _client.on_error(this, MQTTErrorConnectProtocolRetry)
            match _version
            | MQTTv311 =>
              _update_version(MQTTv31)
              _new_connection()
            end
          else
            _client.on_error(this, MQTTErrorConnectProtocol)
          end
        | 2 =>
          if _retry_connection then
            _client.on_error(this, MQTTErrorConnectIDRetry)
            _client_id = MQTTUtils.random_string()
            _new_connection()
          else
            _client.on_error(this, MQTTErrorConnectID)
          end
        | 3 =>
          if _retry_connection then
            _client.on_error(this, MQTTErrorConnectServerRetry)
            _new_connection()
          else
            _client.on_error(this, MQTTErrorConnectServer)
          end
        | 4 =>
          _client.on_error(this, MQTTErrorConnectAuthentication)
        | 5 =>
          _client.on_error(this, MQTTErrorConnectAuthorization)
        else error end
      | 0x3 => // PUBLISH
        let byte: U8 = buffer.peek_u8(0)?
        let qos: U8 = (byte and 0x06) >> 1
        if qos == 0x03 then error end
        let retain: Bool = (byte and 0x01) != 0x00
        let dup: Bool = (byte and 0x08) != 0x00
        buffer.skip(1)?
        // Skip remaining length field
        var temp: U8 = 0x80
        repeat
          temp = temp and buffer.u8()?
        until temp == 0x0 end
        let topic_size: U16 = buffer.u16_be()?
        let topic_block = buffer.block(topic_size.usize())?
        let topic: String = String.from_array(consume topic_block)
        let id: U16 = if qos != 0 then buffer.u16_be()? else 0 end
        let message: Array[U8] val = buffer.block(buffer.size())?
        let packet = MQTTPacket(topic, message, retain, qos, id)
        // QoS
        match qos
        | 0x1 => _puback(packet)
        | 0x2 => _pubrec(packet)
        end
        _client.on_message(this, packet)
      | 0x4 => // PUBACK
        if buffer.peek_u8(0)? != 0x40 then error end
        if buffer.size() != 4 then error end
        buffer.skip(2)?
        _client.on_publish(this, _sent_packets.remove(
          buffer.u16_be()?)?._2)
      | 0x5 => // PUBREC
        if buffer.peek_u8(0)? != 0x50 then error end
        if buffer.size() != 4 then error end
        buffer.skip(2)?
        _pubrel(_sent_packets.remove(buffer.u16_be()?)?._2)
      | 0x6 => // PUBREL
        if buffer.peek_u8(0)? != 0x62 then error end
        if buffer.size() != 4 then error end
        buffer.skip(2)?
        _pubcomp(_received_packets.remove(
          buffer.u16_be()?)?._2)
      | 0x7 => // PUBCOMP
        if buffer.peek_u8(0)? != 0x70 then error end
        if buffer.size() != 4 then error end
        buffer.skip(2)?
        _client.on_publish(this, _confirmed_packets.remove(
          buffer.u16_be()?)?._2)
      | 0x9 => // SUBACK
        if buffer.peek_u8(0)? != 0x90 then error end
        if buffer.size() != 5 then error end
        buffer.skip(2)?
        let topic = _sub_topics.remove(buffer.u16_be()?)?._2._1
        if (buffer.peek_u8(0)? and 0x80) == 0x00 then
          _client.on_subscribe(this, topic, buffer.u8()? and 0x03)
        else
          _client.on_error(this, MQTTErrorSubscribeFailure, topic)
        end
      | 0xB => // UNSUBACK
        if buffer.peek_u8(0)? != 0xB0 then error end
        if buffer.size() != 4 then error end
        buffer.skip(2)?
        _client.on_unsubscribe(this, _unsub_topics.remove(
          buffer.u16_be()?)?._2)
      | 0xD => // PINGRESP
        if buffer.peek_u8(0)? != 0xD0 then error end
        if buffer.size() != 2 then error end
        _client.on_ping(this)
      else
        try
          _client.on_error(
            this,
            MQTTErrorServerCode,
            _unimplemented(buffer.peek_u8(0)?)?)
          _disconnect(true)
        else
          let control_code = buffer.peek_u8(0)?
          _client.on_error(this, MQTTErrorUnknownCode, recover
            let msb = control_code >> 4
            let lsb = control_code and 0xF
            String.from_array(
              [ '0' + msb + if msb > 0x9 then 7 else 0 end
                '0' + lsb + if lsb > 0x9 then 7 else 0 end ])
          end)
          _disconnect(true)
        end
      end
    else
      _client.on_error(this, MQTTErrorUnexpectedFormat)
      _disconnect(true)
    end

  fun ref _end_connection(clear_conn: Bool = true) =>
    """
    Clears data when the connection is ended.
    """
    _is_connected = false
    if clear_conn then
      try (_conn as TCPConnection).dispose() end
      _conn = None
    end
    _packet_id = 0
    _clean_timers()
    _sent_packets.clear()
    _received_packets.clear()
    _confirmed_packets.clear()
    _sub_topics.clear()
    _unsub_topics.clear()

  fun ref _update_version(version: MQTTVersion) =>
    _version = version
    _unimplemented.clear()
    _unimplemented.update(0x10, "CONNECT")
    _unimplemented.update(0x80, "SUBSCRIBE")
    _unimplemented.update(0xA0, "UNSUBSCRIBE")
    _unimplemented.update(0xC0, "PINGREQ")
    _unimplemented.update(0xE0, "DISCONNECT")

  be _new_connection() =>
    _end_connection()
    match _sslctx
    | let ctx: SSLContext =>
      try
        TCPConnection(
          auth,
          SSLConnection(
            _MQTTConnectionHandler(this, auth),
            ctx.client(_sslhost)?),
          host,
          port)
        return
      else
        _client.on_error(this, MQTTErrorTLS)
        return
      end
    else
      TCPConnection(auth, _MQTTConnectionHandler(this, auth), host, port)
    end

  fun ref _connect() =>
    """
    Sends a CONNECTION control packet to the server after establishing
    a TCP connection.
    """
    if _is_connected then
      _client.on_error(this, MQTTErrorConnectConnected)
      return
    end
    if _conn is None then
      _client.on_error(this, MQTTErrorConnectSocket)
      return
    end
    let buffer = Writer
    // -- Variable header --
    // Version
    buffer.write(
      match _version
      | MQTTv311 =>
        [ 0x00; 0x04; 'M'; 'Q'; 'T'; 'T'; 0x04 ]
      | MQTTv31 =>
        [ 0x00; 0x06; 'M'; 'Q'; 'I'; 's'; 'd'; 'p'; 0x03 ]
      end
    )
    // Flags
    buffer.u8(
      0x02 or
      try
        let user = _user as String
        0x80 or
          try
            let pass = _pass as String
            0x40
          else
            0x00
          end
      else
        0x00
      end or
        try
          let will: MQTTPacket = _will_packet as MQTTPacket
            if will.retain then
              0x24
            else
              0x04
            end or
              (will.qos << 3)
        else 0x00 end
    )
    // Keepalive
    buffer.u16_be(_keepalive)
    // -- Payload --
    // ID
    buffer.u16_be(_client_id.size().u16())
    buffer.write(_client_id)
    // Will
    try
      let will: MQTTPacket = _will_packet as MQTTPacket
      buffer.u16_be(will.topic.size().u16())
      buffer.write(will.topic)
      buffer.u16_be(will.message.size().u16())
      buffer.write(will.message)
    end
    // Authentication
    try
      let user = _user as String
      buffer.u16_be(user.size().u16())
      buffer.write(user)
      try
        let pass = _pass as String
        buffer.u16_be(pass.size().u16())
        buffer.write(pass)
      end
    end
    // -- Fixed header --
    let msg_buffer = Writer
    msg_buffer.u8(0x10)
    msg_buffer.write(MQTTUtils.remaining_length(buffer.size()))
    msg_buffer.writev(buffer.done())
    try
      (_conn as TCPConnection).writev(msg_buffer.done())
    end

  fun ref _clean_timers() =>
    try
      _timers.cancel(_ping_timer as Timer tag)
    end
    try
      _timers.cancel(_resend_timer as Timer tag)
    end
    _ping_timer = None
    _resend_timer = None

  fun ref _disconnect(send_will: Bool = false) =>
    if not(_is_connected) then
      _client.on_error(this, MQTTErrorDisconnectDisconnected)
      return
    end
    if send_will then
      try _publish(_will_packet as MQTTPacket) end
    end
    let buffer = Writer
    buffer.u16_le(0xE0)
    try
      (_conn as TCPConnection).writev(buffer.done())
      (_conn as TCPConnection).dispose()
      _end_connection()
    end

  fun ref _subscribe(topic: String, qos: U8 = 0, id: U16 = 0) =>
    if not(MQTTTopic.validate_subscribe(topic)) then
      _client.on_error(this, MQTTErrorSubscribeTopic)
      return
    end
    if qos > 2 then
      _client.on_error(this, MQTTErrorSubscribeQoS)
      return
    end
    if not(_is_connected) then
      _client.on_error(this, MQTTErrorSubscribeConnected)
      return
    end
    let buffer = Writer
    // -- Variable header --
    if id == 0 then
      _packet_id = _packet_id + 1
      buffer.u16_be(_packet_id)
    else
      buffer.u16_be(id)
    end
    // -- Payload --
    buffer.u16_be(topic.size().u16())
    buffer.write(topic)
    buffer.u8(qos)
    // -- Fixed header --
    let msg_buffer = Writer
    msg_buffer.u8(0x82)
    msg_buffer.write(MQTTUtils.remaining_length(buffer.size()))
    msg_buffer.writev(buffer.done())
    _sub_topics.update(if id == 0 then _packet_id else id end, (topic, qos))
    try
      (_conn as TCPConnection).writev(msg_buffer.done())
    end

  fun ref _unsubscribe(topic: String, id: U16 = 0) =>
    if not(MQTTTopic.validate_subscribe(topic)) then
      _client.on_error(this, MQTTErrorUnsubscribeTopic)
      return
    end
    if not(_is_connected) then
      _client.on_error(this, MQTTErrorUnsubscribeConnected)
      return
    end
    let buffer = Writer
    // -- Variable header --
    if id == 0 then
      _packet_id = _packet_id + 1
      buffer.u16_be(_packet_id)
    else
      buffer.u16_be(id)
    end
    // -- Payload --
    buffer.u16_be(topic.size().u16())
    buffer.write(topic)
    // -- Fixed header --
    let msg_buffer = Writer
    msg_buffer.u8(0xA2)
    msg_buffer.write(MQTTUtils.remaining_length(buffer.size()))
    msg_buffer.writev(buffer.done())
    _unsub_topics.update(if id == 0 then _packet_id else id end, topic)
    try
      (_conn as TCPConnection).writev(msg_buffer.done())
    end

  fun ref _publish(packet: MQTTPacket) =>
    if not(MQTTTopic.validate_publish(packet.topic)) then
      _client.on_error(this, MQTTErrorPublishTopic)
      return
    end
    if not(_is_connected) then
      _client.on_error(this, MQTTErrorPublishConnected)
      return
    end
    let buffer = Writer
    // -- Variable header --
    buffer.u16_be(packet.topic.size().u16())
    buffer.write(packet.topic)
    if packet.qos != 0 then
      let id' =
        if packet.id == 0 then
          _packet_id = _packet_id + 1
          _packet_id
        else
          packet.id
        end
      buffer.u16_be(id')
      _sent_packets.update(id', MQTTPacket(
        packet.topic, packet.message, packet.retain, packet.qos, id'))
    end
    // -- Payload --
    buffer.write(packet.message)
    // -- Fixed header --
    let msg_buffer = Writer
    msg_buffer.u8(
      0x30 or
      (if (_sent_packets.contains(packet.id)) then 0x08 else 0x00 end) or
      (packet.qos << 1) or
      (if packet.retain then 0x01 else 0x00 end))
    msg_buffer.write(MQTTUtils.remaining_length(buffer.size()))
    msg_buffer.writev(buffer.done())
    try
      (_conn as TCPConnection).writev(msg_buffer.done())
    end
    if (packet.qos == 0) then _client.on_publish(this, packet) end

  fun ref _puback(packet: MQTTPacket) =>
    """
    Acknowledges a QoS 1 publish from the server.
    """
    let buffer = Writer
    buffer.u16_be(0x4002)
    buffer.u16_be(packet.id)
    try 
      (_conn as TCPConnection).writev(buffer.done())
    end

  fun ref _pubrec(packet: MQTTPacket) =>
    """
    Acknowledges a QoS 2 publish from the server.
    """
    let buffer = Writer
    buffer.u16_be(0x5002)
    buffer.u16_be(packet.id)
    _received_packets.update(packet.id, packet)
    try
      (_conn as TCPConnection).writev(buffer.done())
    end

  fun ref _pubrel(packet: MQTTPacket) =>
    """
    Finalizes a QoS 2 publish from the client.
    """
    let buffer = Writer
    buffer.u16_be(0x6202)
    buffer.u16_be(packet.id)
    _confirmed_packets.update(packet.id, packet)
    try
      (_conn as TCPConnection).writev(buffer.done())
    end

  fun ref _pubcomp(packet: MQTTPacket) =>
    """
    Finalizes a QoS 2 publish from the server.
    """
    let buffer = Writer
    buffer.u16_be(0x7002)
    buffer.u16_be(packet.id)
    try
      (_conn as TCPConnection).writev(buffer.done())
    end

  fun ref _ping() =>
    """
    Pings the server in order to keep the connection alive.
    """
    if not(_is_connected) then
      return
    end
    let buffer = Writer
    buffer.u16_le(0xC0)
    try
      (_conn as TCPConnection).writev(buffer.done())
    end

  be _send_ping() =>
    """
    Timer-callable ping.
    """
    _ping()

  be _resend_packets() =>
    """
    Handles any unconfirmed QoS 1 or 2 publish packets by
    redoing its action.
    """
    if _is_connected then
      for packet in _sent_packets.values() do
        _publish(packet)
      end
      for packet in _received_packets.values() do
        _pubrel(packet)
      end
      for packet in _confirmed_packets.values() do
        _pubcomp(packet)
      end
      for (id, topic_tuple) in _sub_topics.pairs() do
        _subscribe(topic_tuple._1, topic_tuple._2, id)
      end
      for (id, topic) in _unsub_topics.pairs() do
        _unsubscribe(topic, id)
      end
    end

  be disconnect(send_will: Bool = false) =>
    """
    Ends the MQTT and TCP connections.

    If send_will is true, the will packet will be sent before disconnecting.
    """
    _disconnect(send_will)
  
  be subscribe(topic: String, qos: U8 = 0) =>
    """
    Subscribes to a topic.
    """
    _subscribe(topic, qos)
  
  be unsubscribe(topic: String) =>
    """
    Unsubscribes from a topic.
    """
    _unsubscribe(topic)

  be publish(packet: MQTTPacket) =>
    """
    Publishes a packet to a specified topic.

    Strips the connection-specific control ID when requested by the user.
    """
    _publish(MQTTPacket(
      packet.topic,
      packet.message,
      packet.retain,
      packet.qos,
      if _sent_packets.contains(packet.id) then 0 else packet.id end))

  be dispose() =>
    """
    Disposes of this connection.
    """
    _end_connection(true)
