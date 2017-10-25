use "regex"

primitive MQTTTopic
  """
  An utility to validate topics upon publishing or subscribing.
  """
  fun tag validate_publish(topic: String): Bool =>
    """
    Valid PUBLISH topics do not contain '#' or '+'.
    """
    if (topic.size() < 1) or (topic.size() > 65535) then return false end
    not(topic.contains("#"))
      and not(topic.contains("+"))
      and not(topic.contains(String.from_array([0x00])))

  fun tag validate_subscribe(topic: String): Bool =>
    """
    Valid SUBSCRIBE/UNSUBSCRIBE topics may include isolated '#' or '+' between forward dashes.
    """
    if (topic.size() < 1) or (topic.size() > 65535) then return false end
    if topic.contains(String.from_array([0x00])) then return false end
    try
      let r = Regex("^(#|\\/?(([^#\\/\\+]+|\\+)?(\\/([^#\\/\\+]+|\\+))*((\\/\\#)|\\/)?))$")?
      r == topic
    else
      false
    end
