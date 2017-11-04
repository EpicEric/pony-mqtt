use "buffered"
use "collections"
use "random"
use "time"

primitive MQTTUtils
  """
  An utility with functions used throughout MQTTConnection.
  """
  fun tag random_string(
    length: USize = 8,
    letters: String = "0123456789abcdef"): String val =>
  """
  Generates a random string of the specified length with the
  provided characters.
  """
    let length': USize =
      if (length == 0) or (length >= 24) then
        8
      else length end
    var string = recover String(length') end
    let rand: Rand = Rand(Time.nanos()) .> next()
    for n in Range[USize](0, length') do
      try
        let char = rand.int(letters.size().u64()).usize()
        string.push(letters(char)?)
      end
    end
    string

  fun tag remaining_length(length': USize): Array[U8] val =>
  """
  Generates an array of bytes in the format specified by the MQTT protocol
  for the "Remaining Length" field.
  """
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