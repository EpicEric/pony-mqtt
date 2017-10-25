use "buffered"
use "collections"
use "net"
use "random"
use "time"

primitive MQTTv311
primitive MQTTv31
type MQTTVersion is (MQTTv311 | MQTTv31)

interface MQTTConnection
  """
  A public interface to easily pass messages to the broker.
  """
  fun ref disconnect() =>
    """
    Ends connection to the server. Any Will Message will be discarded.
    """
    None

  fun ref subscribe(topic: String, qos: U8 = 0) =>
    """
    Subscribes to a topic.
    """
    None

  fun ref unsubscribe(topic: String) =>
    """
    Unsubscribes from a topic.
    """
    None

  fun ref publish(packet: MQTTPacket) =>
    """
    Publishes a packet to a topic, with QoS settings.
    """
    None

actor _MQTTConnection is MQTTConnection
  """
  An actor that handles the entire MQTT connection.

  It can receive data through a TCPConnectionNotify, or commands from an MQTTClient.
  This allows for all expected abilities from a regular MQTT client.
  """
  let host: String
  let port: String
  let _client: MQTTClient
  let _keepalive: U16
  let _user: (String | None)
  let _pass: (String | None)
  let _version: MQTTVersion
  let _retry_connection: Bool
  let _will_packet: (MQTTPacket | None)
  let _client_id: String
  let _ping_time: U64
  let _resend_time: U64
  let _timers: Timers = Timers
  let _data_buffer: Reader = Reader
  let _unimplemented: Map[U8, String] = _unimplemented.create()
  let _sent_packets: Map[U16, MQTTPacket val] = _sent_packets.create()
  let _received_packets: Map[U16, MQTTPacket val] = _received_packets.create()
  let _confirmed_packets: Map[U16, MQTTPacket val] = _confirmed_packets.create()
  let _sub_topics: Map[U16, String] = _sub_topics.create()
  let _unsub_topics: Map[U16, String] = _unsub_topics.create()
  var _connected: Bool = false
  var _conn: (TCPConnection | None) = None
  var _packet_id: U16 = 0
  var _ping_timer: (Timer tag | None) = None
  var _resend_timer: (Timer tag | None) = None

  new create(
    client': MQTTClient iso,
    host': String = "localhost",
    port': String = "1883",
    keepalive': U16 = 15,
    version': MQTTVersion = MQTTv311,
    retry_connection': Bool = false,
    will_packet': (MQTTPacket | None) = None,
    client_id': String = "",
    user': (String | None) = None,
    pass': (String | None) = None
  ) =>
    host = host'
    port = port'
    _client = consume client'
    _keepalive = if keepalive' > 5 then keepalive' else 5 end
    _user =
      try
        if (user' as String).size() > 0 then user' else None end
      else None end
    _pass = if _user is None then None else pass' end
    _version = version'
    _retry_connection = retry_connection'
    _will_packet = will_packet'
    _client_id = if client_id'.size() >= 6 then client_id' else _random_string() end
    _ping_time = 750_000_000 * _keepalive.u64()
    _resend_time = 1_000_000_000
    _unimplemented.update(0x10, "CONNECT")
    _unimplemented.update(0x80, "SUBSCRIBE")
    _unimplemented.update(0xA0, "UNSUBSCRIBE")
    _unimplemented.update(0xC0, "PINGREQ")
    _unimplemented.update(0xE0, "DISCONNECT")

  fun tag _random_string(length: USize = 8): String val =>
    let length': USize =
      if (length < 1) or (length > 23) then
        8
      else length end
    var string = recover String(length') end
    let rand: Rand = Rand(Time.nanos()).>next()
    let letters: String = "0123456789abcdef"
    for n in Range[USize](0, length') do
      let char = rand.int(letters.size().u64()).usize()
      string.push(try letters(char)? else '0' end)
    end
    string

  fun tag _remaining_length(length': USize): Array[U8] val =>
    let buffer = recover Array[U8] end
    var length = length'
    repeat
      let byte: U8 =
        if length >= 128 then
          (length.u8() and 0x7F) or 0x80
        else
          (length.u8() and 0x7F)
        end
      length = length >> 7
      buffer.push(byte)
    until length == 0 end
    buffer

  be connected(conn: TCPConnection) =>
    _end_connection(false)
    _conn = conn
    _connect()

  be connect_failed(conn: TCPConnection) =>
    _end_connection()
    _client.on_error(this, "[CONNECT] Could not establish a connection")
    if _retry_connection then _connect() end

  be closed(conn: TCPConnection) =>
    let connected' = _connected
    _end_connection()
    if connected' then
      _client.on_error(this, "Connection closed by remote server")
      if _retry_connection then _connect() end
    else
      _client.on_disconnect(this)
    end

  be received(conn: TCPConnection, data: Array[U8] iso,
    times: USize)
  =>
    """
    Combines and breaks received data into control packets, based on the
    remaining length value.
    """
    let full_data: Array[U8] val = consume data
    _data_buffer.append(full_data)
    let buffer = Writer
    try
      while _data_buffer.size() > 0 do
        buffer.u8(_data_buffer.u8()?)
        var remaining_length: USize = 0
        var temp: U8 = 0x80
        repeat
          temp = _data_buffer.u8()?
          remaining_length = (remaining_length << 7) + temp.usize()
          buffer.u8(temp)
        until (temp and 0x80) == 0x0 end
        if remaining_length <= _data_buffer.size() then
          buffer.write(_data_buffer.block(remaining_length)?)
          let packet_data = recover iso Array[U8] end
          for chunk in buffer.done().values() do
            packet_data.append(chunk)
          end
          _parse_packet(consume packet_data)
        else
          try 
            buffer.write(_data_buffer.block(_data_buffer.size())?)
            for chunk in buffer.done().values() do
              _data_buffer.append(chunk)
            end
          end
          break
        end
      end
    end

  be _parse_packet(data: Array[U8] val) =>
    """
    Parses and acts according a single control packet.
    """
    let buffer = Reader
    buffer.append(data)
    try
      if not(_connected) and (buffer.peek_u8(0)? != 0x20) then return end
      match buffer.peek_u8(0)? >> 4
      | 0x2 => // CONNACK
        if buffer.peek_u8(0)? != 0x20 then error end
        if buffer.size() != 4 then error end
        match buffer.peek_u8(3)? // Return code
        | 0 =>
          _connected = true
          // Create a package resender timer and a keepalive timer
          _clean_timers()
          let resend_timer = Timer(_MQTTPingTimer(this), _ping_time, _ping_time)
          _resend_timer = resend_timer
          _timers(consume resend_timer)
          let ping_timer = Timer(_MQTTResendTimer(this), _resend_time, _resend_time)
          _ping_timer = ping_timer
          _timers(consume ping_timer)
          _client.on_connect(this)
        | 1 => _client.on_error(this, "[CONNACK] Unnacceptable protocol version")
        | 2 => _client.on_error(this, "[CONNACK] Connection ID rejected")
        | 3 => _client.on_error(this, "[CONNACK] Server unavailable")
        | 4 => _client.on_error(this, "[CONNACK] Bad user name or password")
        | 5 => _client.on_error(this, "[CONNACK] Unauthorized client")
        else error end
      | 0x3 => // PUBLISH
        let byte: U8 = buffer.peek_u8(0)?
        let qos: U8 = (byte and 0x06) >> 1
        if qos == 0x03 then error end
        let retain: Bool = (byte and 0x01) == 0x01
        //TODO: DUP (0x08) flag
        buffer.skip(1)?
        // Skip remaining length field
        var temp: U8 = 0x80
        repeat
          temp = temp and buffer.u8()?
        until temp == 0x0 end
        let topic_size: U16 = buffer.u16_be()?
        let topic_block = buffer.block(topic_size.usize())?
        let topic: String = String.from_array(consume topic_block)
        let id: U16 = if qos != 0 then
          buffer.u16_be()?
        else
          0
        end
        let message: Array[U8] val = buffer.block(buffer.size())?
        let packet = MQTTPacket(topic, message, qos, retain, id)
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
        _client.on_publish(this, _sent_packets.remove(buffer.u16_be()?)?._2)
      | 0x5 => // PUBREC
        if buffer.peek_u8(0)? != 0x50 then error end
        if buffer.size() != 4 then error end
        buffer.skip(2)?
        _pubrel(_sent_packets.remove(buffer.u16_be()?)?._2)
      | 0x6 => // PUBREL
        if buffer.peek_u8(0)? != 0x62 then error end
        if buffer.size() != 4 then error end
        buffer.skip(2)?
        _pubcomp(_received_packets.remove(buffer.u16_be()?)?._2)
      | 0x7 => // PUBCOMP
        if buffer.peek_u8(0)? != 0x70 then error end
        if buffer.size() != 4 then error end
        buffer.skip(2)?
        _client.on_publish(this, _confirmed_packets.remove(buffer.u16_be()?)?._2)
      | 0x9 => // SUBACK
        if buffer.peek_u8(0)? != 0x90 then error end
        if buffer.size() != 5 then error end
        buffer.skip(2)?
        let topic = _sub_topics.remove(buffer.u16_be()?)?._2
        if (buffer.peek_u8(0)? and 0x80) == 0x00 then
          _client.on_subscribe(this, topic, buffer.u8()? and 0x03)
        else
          let output_err = recover String(topic.size() + 40) end
          output_err.>append("[SUBACK] Could not subscribe to topic '")
            .>append(topic)
            .>append("'")
          _client.on_error(this, consume output_err)
        end
      | 0xB => // UNSUBACK
        if buffer.peek_u8(0)? != 0xB0 then error end
        if buffer.size() != 4 then error end
        buffer.skip(2)?
        _client.on_unsubscribe(this, _unsub_topics.remove(buffer.u16_be()?)?._2)
      | 0xD => // PINGRESP
        if buffer.peek_u8(0)? != 0xD0 then error end
        if buffer.size() != 2 then error end
        _client.on_ping(this)
      else
        try
          let control_code = buffer.peek_u8(0)?
          let control_code_string = _unimplemented(control_code)?
          let output_err = recover String(control_code_string.size() + 48) end
          output_err.>append("[")
            .>append(control_code_string)
            .>append("] Unexpected control code; disconnecting")
          _client.on_error(this, consume output_err)
          disconnect()
        else
          let control_code = buffer.peek_u8(0)?
          let control_code_string = recover String.from_array([
            '0' + (control_code >> 4); '0' + (control_code and 0xF)
          ]) end
          let output_err = recover String(27) end
          output_err.>append("[0x")
            .>append(consume control_code_string)
            .>append("] Unknown control code; disconnecting")
          _client.on_error(this, consume output_err)
          disconnect()
        end
      end
    else
      _client.on_error(this, "Unexpected format when processing packet; disconnecting")
      disconnect()
    end

  fun ref _end_connection(clear_conn: Bool = true) =>
    """
    Clears data when the connection is ended.
    """
    _connected = false
    if clear_conn then _conn = None end
    _packet_id = 0
    _data_buffer.clear()
    _clean_timers()
    _sent_packets.clear()
    _received_packets.clear()
    _confirmed_packets.clear()
    _sub_topics.clear()
    _unsub_topics.clear()

  fun ref _connect() =>
    """
    Sends a CONNECTION control packet to the server after establishing
    a TCP connection.
    """
    if _connected then
      _client.on_error(this, "Cannot connect: Already connected")
      return
    end
    if _conn is None then
      _client.on_error(this, "Cannot connect: No connection established")
      return
    end
    let buffer = Writer
    // -- Variable header --
    // Version
    buffer.write(
      match _version
      | MQTTv311 =>
        [0x00; 0x04; 'M'; 'Q'; 'T'; 'T'; 0x04]
      | MQTTv31 =>
        [0x00; 0x06; 'M'; 'Q'; 'I'; 's'; 'd'; 'p'; 0x03]
      end
    )
    // Flags
    buffer.u8(
      0x02 or
      if _user is String then
        if _pass is String then 0xC0 else 0x80 end
      else 0x00 end or
        try
          let will: MQTTPacket = _will_packet as MQTTPacket
            if will.retain then
              0x20
            else
              0x00
            end or
              (will.qos << 3) or 0x04
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
    // Auth
    try
      if _user is String then
        buffer.u16_be((_user as String).size().u16())
        buffer.write(_user as String)
        if _pass is String then
          buffer.u16_be((_pass as String).size().u16())
          buffer.write(_pass as String)
        end
      end
    end
    // -- Fixed header --
    let msg_buffer = Writer
    msg_buffer.u8(0x10)
    msg_buffer.write(_remaining_length(buffer.size()))
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
    _timers.dispose()

  fun ref disconnect() =>
    """
    Ends the MQTT and TCP connections.
    """
    if not(_connected) then
      _client.on_error(this, "Cannot disconnect: Already disconnected")
      return
    end
    let buffer = Writer
    buffer.u16_le(0xE0)
    try
      (_conn as TCPConnection).writev(buffer.done())
      (_conn as TCPConnection).dispose()
       _end_connection()
    end

  fun ref subscribe(topic: String, qos: U8 = 0) =>
    """
    Subscribes to a topic.
    """
    if not(MQTTTopic.validate_subscribe(topic)) then
      _client.on_error(this, "Cannot subscribe: Invalid topic")
      return
    end
    if qos > 2 then
      _client.on_error(this, "Cannot subscribe: Invalid QoS")
      return
    end
    if not(_connected) then
      _client.on_error(this, "Cannot subscribe: Not connected")
      return
    end
    let buffer = Writer
    // -- Variable header --
    _packet_id = _packet_id + 1
    buffer.u16_be(_packet_id)
    // -- Payload --
    buffer.u16_be(topic.size().u16())
    buffer.write(topic)
    buffer.u8(qos)
    // -- Fixed header --
    let msg_buffer = Writer
    msg_buffer.u8(0x82)
    msg_buffer.write(_remaining_length(buffer.size()))
    msg_buffer.writev(buffer.done())
    _sub_topics.update(_packet_id, topic)
    try
      (_conn as TCPConnection).writev(msg_buffer.done())
    end

  fun ref unsubscribe(topic: String) =>
    """
    Unsubscribes from a topic.
    """
    if not(MQTTTopic.validate_subscribe(topic)) then
      _client.on_error(this, "Cannot unsubscribe: Invalid topic")
      return
    end
    if not(_connected) then
      _client.on_error(this, "Cannot unsubscribe: Not connected")
      return
    end
    let buffer = Writer
    // -- Variable header --
    _packet_id = _packet_id + 1
    buffer.u16_be(_packet_id)
    // -- Payload --
    buffer.u16_be(topic.size().u16())
    buffer.write(topic)
    // -- Fixed header --
    let msg_buffer = Writer
    msg_buffer.u8(0xA2)
    msg_buffer.write(_remaining_length(buffer.size()))
    msg_buffer.writev(buffer.done())
    _unsub_topics.update(_packet_id, topic)
    try
      (_conn as TCPConnection).writev(msg_buffer.done())
    end

  fun ref publish(packet: MQTTPacket) =>
    """
    Publishes a packet to a specified topic.

    Strips the connection-specific control ID when requested by the user.
    """
    _publish(MQTTPacket(
      packet.topic, packet.message, packet.qos, packet.retain,
      if _sent_packets.contains(packet.id) then 0 else packet.id end
    ))

  fun ref _publish(packet: MQTTPacket) =>
    """
    Sends the packet to the topic.
    """
    if not(MQTTTopic.validate_publish(packet.topic)) then
      _client.on_error(this, "Cannot publish: Invalid topic")
      return
    end
    if not(_connected) then
      _client.on_error(this, "Cannot publish: Not connected")
      return
    end
    let buffer = Writer
    // -- Variable header --
    buffer.u16_be(packet.topic.size().u16())
    buffer.write(packet.topic)
    if packet.qos != 0 then
      let id' = if packet.id == 0 then
        _packet_id = _packet_id + 1
        _packet_id
      else packet.id end
      buffer.u16_be(id')
      _sent_packets.update(id', MQTTPacket(packet.topic, packet.message, packet.qos, packet.retain, id'))
    end
    // -- Payload --
    buffer.write(packet.message)
    // -- Fixed header --
    let msg_buffer = Writer
    msg_buffer.u8(
      0x30 or
      (if (_sent_packets.contains(packet.id)) then 0x08 else 0x00 end) or
      (packet.qos << 1) or
      (if packet.retain then 0x01 else 0x00 end)
    )
    msg_buffer.write(_remaining_length(buffer.size()))
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
    if not(_connected) then
      _client.on_error(this, "Cannot ping: Not connected")
      return
    end
    let buffer = Writer
    buffer.u16_le(0xC0)
    try
      (_conn as TCPConnection).writev(buffer.done())
    end

  be ping() =>
    """
    User-callable ping.
    """
    _ping()

  be resend_packets() =>
    """
    Handles any unconfirmed QoS 1 or 2 publish packets by
    redoing its action.
    """
    if _connected then
      for packet in _sent_packets.values() do
        _publish(packet)
      end
      for packet in _received_packets.values() do
        _pubrel(packet)
      end
      for packet in _confirmed_packets.values() do
        _pubcomp(packet)
      end
    end
