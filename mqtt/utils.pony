use "random"
use "time"

primitive MQTTUtils
  """
  An utility to generate intermediate values in MQTTConnection.
  """

  fun random_string(
    length: USize = 8,
    letters: String = "0123456789abcdef"): String iso^
  =>
    """
    Generates a random string of the specified length with the
    provided characters.
    """
    recover
      let length': USize =
        if (length == 0) or (length > 23) then
          8
        else length end
      var string = String(length')
      let rand: Rand = Rand(Time.nanos())
      var n: USize = 0
      while n < length' do
        try
          let char = rand.int(letters.size().u64()).usize()
          string.push(letters(char)?)
        end
        n = n + 1
      end
      string
    end

  fun remaining_length(length: USize): Array[U8] val =>
    """
    Generates an array of bytes in the format specified by the MQTT protocol
    for the "Remaining Length" field, encoding the provided integer.
    """
    let buffer = recover Array[U8] end
    var length' = length
    repeat
      let byte: U8 =
        if length' >= 128 then
          (length'.u8() and 0x7F) or 0x80
        else
          (length'.u8() and 0x7F)
        end
      length' = length' >> 7
      buffer.push(byte)
    until length' == 0 end
    buffer
