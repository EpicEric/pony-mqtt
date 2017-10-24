use "regex"

primitive MQTTTopic
  fun tag validate_publish(topic: String): Bool =>
    if (topic.size() < 1) or (topic.size() > 65535) then return false end
    not(topic.contains("#"))
      and not(topic.contains("+"))
      and not(topic.contains(String.from_array([0x00])))

  fun tag validate_subscribe(topic: String): Bool =>
    if (topic.size() < 1) or (topic.size() > 65535) then return false end
    if topic.contains(String.from_array([0x00])) then return false end
    try
      let r = Regex("^((\\#)|(([^#\\/\\+]+|\\+)?(\\/([^#\\/\\+]+|\\+))*(\\/\\#)?))$")?
      r == topic
    else
      false
    end
