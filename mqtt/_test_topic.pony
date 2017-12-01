use "ponytest"

actor _TestTopic is TestList
  """
  Unit tests that verify the functionality of the methods in the MQTTTopic
  primitive.
  """

  fun tag tests(test: PonyTest) =>
    test(_TestTopicPublishValid)
    test(_TestTopicPublishInvalid)
    test(_TestTopicSubscribeValid)
    test(_TestTopicSubscribeInvalid)
    test(_TestTopicMatchValid)
    test(_TestTopicMatchInvalid)

class _TestTopicPublishValid is UnitTest
  """
  Verify that the following PUBLISH topics are valid.
  """

  fun name(): String =>
    "MQTT/Topic/PublishValid"

  fun label(): String =>
    "topic"

  fun ref apply(h: TestHelper) =>
    h.assert_true(MQTTTopic.validate_publish("/"))
    h.assert_true(MQTTTopic.validate_publish("pony"))
    h.assert_true(MQTTTopic.validate_publish("Úñïçøð€"))
    h.assert_true(MQTTTopic.validate_publish("/test"))
    h.assert_true(MQTTTopic.validate_publish("weird/"))
    h.assert_true(MQTTTopic.validate_publish("foo/biz/bar"))
    h.assert_true(MQTTTopic.validate_publish("$SYS/version"))
    h.assert_true(MQTTTopic.validate_publish("///"))

class _TestTopicPublishInvalid is UnitTest
  """
  Verify that the following PUBLISH topics are invalid.
  """

  fun name(): String =>
    "MQTT/Topic/PublishInvalid"

  fun label(): String =>
    "topic"

  fun ref apply(h: TestHelper) =>
    h.assert_false(MQTTTopic.validate_publish(""))
    h.assert_false(MQTTTopic.validate_publish(String.from_array(
      recover Array[U8].init('a', 65536) end)))
    h.assert_false(MQTTTopic.validate_publish("+"))
    h.assert_false(MQTTTopic.validate_publish("#"))
    h.assert_false(MQTTTopic.validate_publish(String.from_array(
      ['A'; 0x00; 'B'])))
    h.assert_false(MQTTTopic.validate_publish("123+456#789"))
    h.assert_false(MQTTTopic.validate_publish("$SYS/#"))
    h.assert_false(MQTTTopic.validate_publish("foo/+/bar"))

class _TestTopicSubscribeValid is UnitTest
  """
  Verify that the following SUBSCRIBE topics are valid.
  """

  fun name(): String =>
    "MQTT/Topic/SubscribeValid"

  fun label(): String =>
    "topic"

  fun ref apply(h: TestHelper) =>
    h.assert_true(MQTTTopic.validate_subscribe("/"))
    h.assert_true(MQTTTopic.validate_subscribe("pony"))
    h.assert_true(MQTTTopic.validate_subscribe("Úñïçøð€"))
    h.assert_true(MQTTTopic.validate_subscribe("/test"))
    h.assert_true(MQTTTopic.validate_subscribe("weird/"))
    h.assert_true(MQTTTopic.validate_subscribe("foo/biz/bar"))
    h.assert_true(MQTTTopic.validate_subscribe("#"))
    h.assert_true(MQTTTopic.validate_subscribe("+"))
    h.assert_true(MQTTTopic.validate_subscribe("+/+"))
    h.assert_true(MQTTTopic.validate_subscribe("$SYS/#"))
    h.assert_true(MQTTTopic.validate_subscribe("/#"))
    h.assert_true(MQTTTopic.validate_subscribe("/+"))
    h.assert_true(MQTTTopic.validate_subscribe("+/+/tennis/#"))
    h.assert_true(MQTTTopic.validate_subscribe("///"))

class _TestTopicSubscribeInvalid is UnitTest
  """
  Verify that the following SUBSCRIBE topics are invalid.
  """

  fun name(): String =>
    "MQTT/Topic/SubscribeInvalid"

  fun label(): String =>
    "topic"

  fun ref apply(h: TestHelper) =>
    h.assert_false(MQTTTopic.validate_subscribe(""))
    h.assert_false(MQTTTopic.validate_subscribe(String.from_array(
      recover Array[U8].init('a', 65536) end)))
    h.assert_false(MQTTTopic.validate_subscribe(String.from_array(
      ['A'; 0x00; 'B'])))
    h.assert_false(MQTTTopic.validate_subscribe("#/"))
    h.assert_false(MQTTTopic.validate_subscribe("#/hi"))
    h.assert_false(MQTTTopic.validate_subscribe("+hello"))
    h.assert_false(MQTTTopic.validate_subscribe("hel+lo"))
    h.assert_false(MQTTTopic.validate_subscribe("hello+"))
    h.assert_false(MQTTTopic.validate_subscribe("good/#morning"))
    h.assert_false(MQTTTopic.validate_subscribe("good/morn#ing"))
    h.assert_false(MQTTTopic.validate_subscribe("good/morning#"))

class _TestTopicMatchValid is UnitTest
  """
  Verify that the topics match the provided filters.
  """

  fun name(): String =>
    "MQTT/Topic/MatchValid"

  fun label(): String =>
    "topic"

  fun ref apply(h: TestHelper) =>
    h.assert_true(MQTTTopic.match_topic("pony/lang", "pony/lang"))
    h.assert_true(MQTTTopic.match_topic("foo/biz/bar", "foo/+/bar"))
    h.assert_true(MQTTTopic.match_topic("hello/world", "+/world"))
    h.assert_true(MQTTTopic.match_topic("a/very/long/topic", "#"))
    h.assert_true(MQTTTopic.match_topic("topic/with/$dollar", "topic/with/+"))
    h.assert_true(MQTTTopic.match_topic("three/whole/levels", "+/+/#"))
    h.assert_true(MQTTTopic.match_topic("exactly/two", "+/+"))
    h.assert_true(MQTTTopic.match_topic("$SYS/some/stuff", "$SYS/#"))
    h.assert_true(MQTTTopic.match_topic("/finance", "+/+"))
    h.assert_true(MQTTTopic.match_topic("/finance", "/+"))

class _TestTopicMatchInvalid is UnitTest
  """
  Verify that the topics do not match the provided filters.
  """

  fun name(): String =>
    "MQTT/Topic/MatchInvalid"

  fun label(): String =>
    "topic"

  fun ref apply(h: TestHelper) =>
    h.assert_false(MQTTTopic.match_topic("pony/lang", "pony/lang/"))
    h.assert_false(MQTTTopic.match_topic("pony/lang/", "pony/lang"))
    h.assert_false(MQTTTopic.match_topic("+/biz/bar", "#"))
    h.assert_false(MQTTTopic.match_topic("mashed/potatoes", "mashed#"))
    h.assert_false(MQTTTopic.match_topic("$SYS/some/stuff", "#"))
    h.assert_false(MQTTTopic.match_topic("two/topics", "+/+/+"))
    h.assert_false(MQTTTopic.match_topic("/finance", "+"))
