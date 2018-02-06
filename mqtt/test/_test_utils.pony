use "collections"
use "ponytest"

use ".."

actor _TestUtils is TestList
  """
  Unit tests that verify the functionality of the methods in the MQTTUtils
  primitive.
  """

  fun tag tests(test: PonyTest) =>
    test(_TestUtilsRandomString)
    test(_TestUtilsRemainingLength)

class _TestUtilsRandomString is UnitTest
  """
  Verify that the generated random strings respect expected inputs.
  """

  fun name(): String =>
    "MQTT/Utils/RandomString"

  fun label(): String =>
    "utils"

  fun ref apply(h: TestHelper) =>
    for i in Range(0, 10) do
      let str1: String = MQTTUtils.random_string()
      h.assert_eq[USize](str1.size(), 8)
      for c in str1.values() do
        h.assert_true("0123456789abcdef".array().contains(c))
      end
      let str2: String = MQTTUtils.random_string(4, "xyz")
      h.assert_eq[USize](str2.size(), 4)
      for c in str2.values() do
        h.assert_true("xyz".array().contains(c))
      end
      let str3: String = MQTTUtils.random_string(23, "()")
      h.assert_eq[USize](str3.size(), 23)
      for c in str3.values() do
        h.assert_true("()".array().contains(c))
      end
    end

class _TestUtilsRemainingLength is UnitTest
  """
  Verify that the generated remaining length arrays are correct.
  """

  fun name(): String =>
    "MQTT/Utils/RemainingLength"

  fun label(): String =>
    "utils"

  fun ref apply(h: TestHelper) =>
    h.assert_array_eq[U8](
      MQTTUtils.remaining_length(0), [0x00])
    h.assert_array_eq[U8](
      MQTTUtils.remaining_length(127), [0x7F])
    h.assert_array_eq[U8](
      MQTTUtils.remaining_length(128), [0x80; 0x01])
    h.assert_array_eq[U8](
      MQTTUtils.remaining_length(16_383), [0xFF; 0x7F])
    h.assert_array_eq[U8](
      MQTTUtils.remaining_length(16_384), [0x80; 0x80; 0x01])
    h.assert_array_eq[U8](
      MQTTUtils.remaining_length(2_097_151), [0xFF; 0xFF; 0x7F])
    h.assert_array_eq[U8](
      MQTTUtils.remaining_length(2_097_152), [0x80; 0x80; 0x80; 0x01])
    h.assert_array_eq[U8](
      MQTTUtils.remaining_length(268_435_455), [0xFF; 0xFF; 0xFF; 0x7F])
