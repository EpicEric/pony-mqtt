use "backpressure"
use "buffered"
use "net"

class _MQTTConnectionHandler is TCPConnectionNotify
  """
  A TCPConnectionNotify class that handles and redirects all messages
  to an MQTTConnection actor.
  """
  let _connection: MQTTConnection
  let _auth: BackpressureAuth
  let _data_buffer: Reader = Reader

  new iso create(connection: MQTTConnection, auth: BackpressureAuth) =>
    _connection = connection
    _auth = auth

  fun ref connected(conn: TCPConnection ref) =>
    _connection._connected(conn, this)

  fun ref connect_failed(conn: TCPConnection ref) =>
    _connection._connect_failed(conn, this)

  fun ref closed(conn: TCPConnection ref) =>
    _data_buffer.clear()
    _connection._closed(conn, this)

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso,
    times: USize): Bool =>
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
        var shift_amount: USize = 0
        var temp: U8 = 0x80
        repeat
          temp = _data_buffer.u8()?
          remaining_length =
            remaining_length + ((temp and 0x7F).usize() << shift_amount)
          shift_amount = shift_amount + 7
          buffer.u8(temp)
        until (temp and 0x80) == 0x0 end
        if remaining_length <= _data_buffer.size() then
          buffer.write(_data_buffer.block(remaining_length)?)
          let packet_data = recover iso Array[U8] end
          for chunk in buffer.done().values() do
            packet_data.append(chunk)
          end
          _connection._parse_packet(conn, this, consume packet_data)
        else
          error
        end
      end
    else
      try buffer.write(_data_buffer.block(_data_buffer.size())?) end
      for chunk in buffer.done().values() do
        _data_buffer.append(chunk)
      end
    end
    true

  fun ref auth_failed(conn: TCPConnection ref) =>
    _connection._auth_failed(conn, this)

  fun ref throttled(conn: TCPConnection ref) =>
    Backpressure.apply(_auth)

  fun ref unthrottled(conn: TCPConnection ref) =>
    Backpressure.release(_auth)
